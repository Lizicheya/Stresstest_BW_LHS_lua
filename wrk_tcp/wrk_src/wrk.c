
#include "wrk.h"
#include "script.h"
#include "net.h"
#include "main.h"

#ifndef HAVE_WSAPOLL
#include <netdb.h>
#endif

static config cfg;
static volatile sig_atomic_t stop = 0;
static volatile sig_atomic_t done_threads = 0; /* 已跑完全部业务用例的线程数,达到线程总数时提前结束压测 */

static struct {
    stats *latency;
    stats *requests;
} statistics;

static struct sock sock = {
    .connect  = sock_connect,
    .close    = sock_close,
    .read     = sock_read,
    .write    = sock_write,
    .readable = sock_readable
};

static struct http_parser_settings parser_settings = {
    .on_message_complete = response_complete,
    .on_body             = response_body,
};

static void handler(int sig) {
    stop = 1;
}

bool init_config(config *c) {
    lua_State *L = luaL_newstate();
    luaL_openlibs(L);

    luaL_loadfile(L, "config.lua");
    lua_pcall(L, 0, 1, 0); //-1 table

    lua_pushnil(L);  //-1 nil -2 table
    while (lua_next(L, -2) != 0) { // pop -1 
    	int keyt = lua_type(L, -2);
		if (keyt != LUA_TSTRING) {
            return false;
		}
        const char *key = lua_tostring(L, -2);	//-1 value -2 key -3 table
        if (strcmp(key, "connections") == 0) {
            c->connections = lua_tointeger(L, -1);
        }else if (strcmp(key, "threads") == 0) {
            c->threads = lua_tointeger(L, -1);
        }else if (strcmp(key, "host") == 0) {
            const char *value = lua_tostring(L, -1);
            int len = strlen(value)+1;
            c->host = zcalloc(len);
            memcpy(c->host, value, len);
        }else if (strcmp(key, "duration") == 0) {
            c->duration = lua_tointeger(L, -1);
        }else if (strcmp(key, "port") == 0) {
            c->port = lua_tointeger(L, -1);
        }else if (strcmp(key, "timeout") == 0) {
            c->timeout = lua_tointeger(L, -1);
        }else if (strcmp(key, "debug") == 0) {
            c->debug = lua_toboolean(L, -1);
        }else if (strcmp(key, "url") == 0) {
            const char *value = lua_tostring(L, -1);
            int len = strlen(value)+1;
            c->url = zcalloc(len);
            memcpy(c->url, value, len);
        }

        lua_pop(L, 1); //pop value => -1 key -2 table
    }
    lua_close(L);

    return true;
}

static uint64_t time_us() {
#ifdef HAVE_WSAPOLL
    /* Windows:使用 QueryPerformanceCounter 或 GetSystemTimeAsFileTime */
    FILETIME ft;
    ULARGE_INTEGER li;
    /* Windows epoch(1601)到 Unix epoch(1970)差 11644473600 秒 */
    const uint64_t EPOCH_OFFSET = 116444736000000000ULL;
    GetSystemTimeAsFileTime(&ft);
    li.LowPart = ft.dwLowDateTime;
    li.HighPart = ft.dwHighDateTime;
    uint64_t time = li.QuadPart - EPOCH_OFFSET;
    return (time / 10ULL);  /* 100ns -> 微秒 */
#else
    struct timeval t;
    gettimeofday(&t, NULL);
    return (t.tv_sec * 1000000) + t.tv_usec;
#endif
}

int record_rate(aeEventLoop *loop, long long id, void *data) {
    // thread *thread = data;
    if (stop) aeStop(loop);

    return RECORD_INTERVAL_MS;
}

// 周期性重新触发所有连接的可写事件,使 Lua 层的超时检测能执行
// 当连接处于等待响应状态且服务器不响应时,AE_WRITABLE 会被移除,
// 此定时器确保 writeable 仍被定期调用以检测超时
#define REARM_WRITEABLE_MS  500
int rearm_writeable(aeEventLoop *loop, long long id, void *data) {
    thread *t = data;
    connection *c = t->cs;
    for (uint64_t i = 0; i < t->connections; i++, c++) {
        /* connecting 也纳入兜底:writeable 内 reconnect 会留下 connecting=1
         * 且 length>0(请求帧待发)的短暂状态,若 WSAPoll 偶发不报告 POLLOUT,
         * 需由本定时器调用 socket_writeable 转交 socket_connected 完成建连
         * 确认,帧随后由 writeable 正常发出,否则连接同样沉默卡死。
         * 原条件 c->length==0 && c->written==0 仅触发空连接,漏掉 connecting
         * 帧待发场景,导致 reqlogin 帧永久挂起无法驱动握手确认。
         *
         * 另一兜底用途:WSAPoll 对已注册 AE_WRITABLE 的连接偶发不报告
         * POLLOUT,直接调用 socket_writeable 刷新发送队列作为 fallback:
         * - script_writeable 取走 send_queue 里的 reqlogin/reqAuth 发出
         * - 队列空时返回空串,c->length=0,无副作用
         * 每 500ms 直接调用是安全的(Lua 侧 pcall 防御) */
        /* 无条件刷新:原条件 c->connecting || (c->length==0 && c->written==0) 会漏掉
         * 某些中间状态(如 reconnect 后 length>0 但 connecting=0 的帧待发场景,
         * 或 AE_WRITABLE 被删除但 c->length>0 的部分写入场景),导致连接完全静默、
         * 连第一次 TIMEOUT 都不出现、thread 无法 early stop。
         * socket_writeable 内部已有 c->length>0 跳过 script_writeable 直接
         * sock.write 的逻辑,无脑调用是安全的 */
        if (c->fd >= 0) {
            aeCreateFileEvent(loop, c->fd, AE_WRITABLE, socket_writeable, c);
            socket_writeable(loop, c->fd, c, AE_WRITABLE);
        }
    }
    return REARM_WRITEABLE_MS;
}

// Lua C 函数:wrk.reconnect(fd, host, port)
// 关闭旧连接(登录服),建立到新地址(网关 gatewayHost:gatewayPort)的连接
// 模拟 Python 双连接流程:reqlogin 后切换到网关发 reqAuth 和业务协议
// thread 指针由 script_register_wrk 存入 Lua 全局 wrk_thread(lightuserdata)
// 返回:新 fd(整数) 成功; nil, err 失败
static int lua_reconnect(lua_State *L) {
    int fd = luaL_checkinteger(L, 1);
    const char *host = luaL_checkstring(L, 2);
    int port = luaL_checkinteger(L, 3);

    lua_getglobal(L, "wrk_thread");
    if (!lua_islightuserdata(L, -1)) {
        lua_pushnil(L);
        lua_pushstring(L, "wrk_thread not set");
        return 2;
    }
    thread *t = (thread *)lua_touserdata(L, -1);
    lua_pop(L, 1);

    // 遍历本线程连接数组,按 fd 查找 connection
    connection *c = t->cs;
    connection *found = NULL;
    for (uint64_t i = 0; i < t->connections; i++, c++) {
        if (c->fd == fd) { found = c; break; }
    }
    if (!found) {
        lua_pushnil(L);
        lua_pushstring(L, "fd not found");
        return 2;
    }

    // 清理旧连接的事件并关闭 fd
    aeEventLoop *loop = t->loop;
    aeDeleteFileEvent(loop, fd, AE_READABLE | AE_WRITABLE);
#ifdef HAVE_WSAPOLL
    closesocket(fd);
#else
    close(fd);
#endif
    found->fd = -1;
    found->length = found->written = 0;
    if (found->request) { free(found->request); found->request = NULL; }
    found->host = (char *)host;
    found->port = port;

    // 建立到新地址的连接,成功后 socket_connected 会触发 script_connected
    int newfd = connect_socket(t, found);
    if (newfd < 0) {
        lua_pushnil(L);
        lua_pushstring(L, "connect_socket failed");
        return 2;
    }
    lua_pushinteger(L, newfd);
    return 1;
}

// Lua C 函数:wrk.report_done()
// 本线程 Lua 侧检测到所有连接的业务用例已全部跑完后上报,
// 主线程每秒检查 done_threads 达到线程总数即提前结束压测
static int lua_report_done(lua_State *L) {
    lua_getglobal(L, "wrk_thread");
    if (!lua_islightuserdata(L, -1)) {
        lua_pushnil(L);
        lua_pushstring(L, "wrk_thread not set");
        return 2;
    }
    thread *t = (thread *)lua_touserdata(L, -1);
    lua_pop(L, 1);
    if (t && !t->task_done) {
        t->task_done = 1;
        done_threads++;
    }
    return 0;
}

// 注册 wrk Lua 表:wrk.reconnect(fd, host, port)、wrk.report_done(),并存 thread 到全局 wrk_thread
// 在 thread_main 中 script_start 之后调用,供 Lua 层切换连接到网关/上报任务完成
void script_register_wrk(lua_State *L, thread *t) {
    lua_pushlightuserdata(L, t);
    lua_setglobal(L, "wrk_thread");
    lua_newtable(L);
    lua_pushcfunction(L, lua_reconnect);
    lua_setfield(L, -2, "reconnect");
    lua_pushcfunction(L, lua_report_done);
    lua_setfield(L, -2, "report_done");
    lua_setglobal(L, "wrk");
}

static int connect_socket(thread *thread, connection *c) {
    struct aeEventLoop *loop = thread->loop;
    int fd;

    fd = socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
    if (fd == -1) {
#ifdef HAVE_WSAPOLL
        int wsaerr = WSAGetLastError();
        printf("socket failed, wsaerr:%d\n", wsaerr);
#else
        printf("socket failed, errno:%d, errmsg:%s\n", errno, strerror(errno));
#endif
        goto error;
    }

#ifdef HAVE_WSAPOLL
    /* Windows:直接 ioctlsocket 设非阻塞 */
    wrk_set_nonblock(fd);
#else
    int flags = fcntl(fd, F_GETFL, 0);
    fcntl(fd, F_SETFL, flags | O_NONBLOCK);
#endif

	struct sockaddr_in my_addr;
	my_addr.sin_addr.s_addr=inet_addr(c->host);
	my_addr.sin_family=AF_INET;
	my_addr.sin_port=htons(c->port);

    if (connect(fd, (struct sockaddr *)&my_addr,sizeof(struct sockaddr_in)) == -1) {
#ifdef HAVE_WSAPOLL
        int wsaerr = WSAGetLastError();
        if (wsaerr != WSAEWOULDBLOCK) {
            printf("connect failed, wsaerr:%d\n", wsaerr);
            goto error;
        }
#else
        if (errno != EINPROGRESS) { //正在连接中
            printf("connect failed, errno:%d, errmsg:%s\n", errno, strerror(errno));
            goto error;
        }
#endif
    }

    int tcp_nodelay = 1;
    setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, (const char*)&tcp_nodelay, sizeof(tcp_nodelay)); //禁用Nagle算法

    int ev_flags = AE_READABLE | AE_WRITABLE;
    if (aeCreateFileEvent(loop, fd, ev_flags, socket_connected, c) == AE_OK) {
        if (c->http) {
            c->parser.data = c;
        }
        c->fd = fd;
        c->connecting = 1; /* 握手未完成,等待 POLLOUT 触发 socket_connected 确认 */
        return fd;
    }

  error:
    printf("connect error\n");
    thread->errors.connect++;
    close(fd);
    return -1;
}

static void socket_connected(aeEventLoop *loop, int fd, void *data, int mask) {
    connection *c = data;

    switch (sock.connect(c, cfg.host)) {
        case OK:    break;
        case ERROR: goto error;
        case RETRY: return;
    }
    c->connecting = 0; /* 握手确认完成,解除 rearm保护 */
    /* 诊断:确认连接到达 script_connected 阶段(定位 50 连接仅 9 个 writeable) */
    if (cfg.debug) {
        fprintf(stderr, "[dbg] connected fd=%d\n", fd);
    }
    fflush(stderr);
    if (c->http) {
        http_parser_init(&c->parser, HTTP_RESPONSE);
    }

    script_connected(c->thread->L, fd);
    aeCreateFileEvent(c->thread->loop, fd, AE_READABLE, socket_readable, c);
    aeCreateFileEvent(c->thread->loop, fd, AE_WRITABLE, socket_writeable, c);

    stats_connect(statistics.latency);
    // printf("statistics.latency:%"PRIu64"\n", statistics.latency->connects);

    return;

  error:
    c->thread->errors.connect++;
}

static void socket_writeable(aeEventLoop *loop, int fd, void *data, int mask) {
    connection *c = data;
    thread *thread = c->thread;

    if (c->connecting) {
        /* 兕底:握手未完成时被误调,转交 socket_connected 完成建连流程 */
        socket_connected(loop, fd, data, mask);
        return;
    }
    /* 仅在无待发帧(c->length==0)且未写过(c->written==0)时才调用 script_writeable 取新帧。
     * relogin 在 writeable 内被调用时:wrk.reconnect 设置 c->connecting=1,reqlogin 帧被
     * Lua 取到 c->request,但 c->connecting==1 使 sock.write 被跳过,帧保留在 c->request。
     * 若下次 writeable 仍走 script_writeable,Lua send_queue 已空(relogin 已取走帧),
     * 状态机 STATE_WAIT_LOGIN 不会重产 reqlogin,c->request 被覆盖为 NULL,reqlogin 帧永久
     * 丢失,服务器收不到 reqlogin 持续超时直至 abandon。c->length>0 时跳过取帧直接发送
     * 剩余部分,既兼容部分写入(c->written>0)重发,也兼容 reconnect 后帧保留场景 */
    if (c->length == 0 && c->written == 0) {
        if (c->http) {
            script_http_writeable(thread->L, fd, &c->request, &c->length);
        }else {
            script_writeable(thread->L, fd, &c->request, &c->length);
        }
        /* script_writeable 内 Lua 可能调用 wrk.reconnect 重建连接(网关切换/
         * 账号轮换切回登录服),返回时 c->connecting=1 且新 fd 握手未完成。
         * 此时不得对未握手 socket 执行 send:WSAENOTCONN 走 error 分支删除
         * AE_WRITABLE(连带 socket_connected 注册),且 c->length 残留 >0 使
         * rearm_writeable 永久跳过,连接沉默卡死(reqlogin 永不发出)。
         * 帧保留在 c->request,握手完成后由后续 writeable 触发发出 */
        if (c->connecting) {
            return;
        }
    }
    if (c->length == 0) {
        aeDeleteFileEvent(loop, fd, AE_WRITABLE);
    }else {
        c->start   = time_us();

        char  *buf = c->request + c->written; //非阻塞套接字有可能缓冲区不够，会多次写
        int len = c->length  - c->written;
        size_t n;

        switch (sock.write(c, buf, len, &n)) {  //应用程序写入的数据大于套接字缓冲区大小，这将会发生拆包。
            case OK:    break;
            case ERROR: goto error;  //内核缓冲区没有空间
            case RETRY: return;
        }
        c->written += n;
        if (c->written == c->length) {
            thread->reqcount++;
            c->length = c->written = 0;
            free(c->request);
            c->request = NULL;
            aeDeleteFileEvent(loop, fd, AE_WRITABLE);
        }
    }

    return;

  error:
    /* 清理事件:避免 send 失败后 WSAPoll 持续返回该 fd 事件重复触发 */
    aeDeleteFileEvent(loop, fd, AE_WRITABLE);
#ifdef HAVE_WSAPOLL
    /* Windows 下 POSIX errno 无意义(恒为 0),须用 WSAGetLastError */
    int wsaerr = WSAGetLastError();
    /* WSAENOTCONN(10057):退出过渡窗口内 reconnect 已 closesocket 旧 fd,
     * 但 WSAPoll 仍可能返回残留事件触发 socket_writeable,属预期错误,
     * 静默处理不污染 errors.write 统计 */
    if (wsaerr != WSAENOTCONN) {
        printf("write failed, wsaerr:%d\n", wsaerr);
        thread->errors.write++;
    }
#else
    printf("write failed, errno:%d, errmsg:%s\n", errno, strerror(errno));
    thread->errors.write++;
#endif
}

static int response_body(http_parser *parser, const char *at, size_t len) {
    connection *c = parser->data;
    buffer_append(&c->body, at, len);
    return 0;
}

static int response_complete(http_parser *parser) {
    connection *c = parser->data;
    thread *thread = c->thread;

    int status = parser->status_code;
    if (status > 399) {
        thread->errors.status++;
    }
    uint64_t now = time_us();
    thread->complete++;
    if (!stats_record(statistics.latency, now - c->start)) {
        thread->errors.timeout++;
    }
    script_response(thread->L, c->fd, status, &c->headers, &c->body);
    http_parser_init(parser, HTTP_RESPONSE);

    return 0;
}

static void socket_readable(aeEventLoop *loop, int fd, void *data, int mask) {
    connection *c = data;
    thread *thread = c->thread;

    size_t n;
    do {
        switch (sock.read(c, &n)) {
            case OK:    break;
            case ERROR: goto error;
            case RETRY: return;
        }
        if(n == 0) { //end of file
            break;
        }

        if (c->http) {
            if (http_parser_execute(&c->parser, &parser_settings, (char*)c->buf, n) != n) goto error;
            if (n == 0 && !http_body_is_final(&c->parser)) goto error;
        }else {
            unsigned char * ptr = malloc(sizeof(unsigned char)*n);
            memmove(ptr, c->buf, n);

            int readover = 0;
            int result = script_readable(thread->L, fd, ptr, n, &readover);

            if (readover == 0) {
                uint64_t now = time_us();
                if (!stats_record(statistics.latency, now - c->start)) {
                    thread->errors.timeout++;
                }
                
                thread->complete += result;
                /* 重连产生新 fd 时,旧 fd 上残留的 socket_readable 可能在
                   connecting=1 期间触发,此处若重新注册 AE_WRITABLE->socket_writeable,
                   旧 fd 后续可写触发会被 socket_writeable 的兜底转交 socket_connected,
                   导致回调指针覆盖、新旧 fd 事件表错乱 */
                if (c->connecting == 0) {
                    aeCreateFileEvent(thread->loop, c->fd, AE_WRITABLE, socket_writeable, c);
                }
            }else if (readover == -1){
                thread->complete += result;
            }else if (readover == -2){
                // printf("ccccc\n");
            }
        }

        c->thread->bytes += n;
    } while (n == RECVBUF && sock.readable(c) > 0);

    return;

  error:
    printf("read failed, errno:%d, errmsg:%s\n", errno, strerror(errno));
    c->thread->errors.read++;
}

static char *copy_url_part(char *url, struct http_parser_url *parts, enum http_parser_url_fields field) {
    char *part = NULL;

    if (parts->field_set & (1 << field)) {
        uint16_t off = parts->field_data[field].off;
        uint16_t len = parts->field_data[field].len;
        part = zcalloc(len + 1 * sizeof(char));
        memcpy(part, &url[off], len);
    }

    return part;
}

void http_addr(char ** host, int *port) {
    struct addrinfo *addrs;
    struct addrinfo hints = {
        .ai_family   = AF_UNSPEC,
        .ai_socktype = SOCK_STREAM
    };
    struct http_parser_url parts = {};
    http_parser_parse_url(cfg.url, strlen(cfg.url), 0, &parts);
    char * domain  = copy_url_part(cfg.url, &parts, UF_HOST);
    char * service = copy_url_part(cfg.url, &parts, UF_PORT);

    getaddrinfo(domain, service, &hints, &addrs);
    getnameinfo(addrs->ai_addr, addrs->ai_addrlen, domain, NI_MAXHOST, NULL, NI_MAXSERV, NI_NUMERICHOST|NI_NUMERICSERV);
    *host = domain;
    *port = atoi(service);

    freeaddrinfo(addrs);
}

void *thread_main(void *arg) {
    thread *thread = arg;

    script_start(thread->L, thread->identify, thread->connections);

    // 注册 wrk.reconnect 并注入 thread 指针,供 Lua 切换连接到网关
    script_register_wrk(thread->L, thread);

    thread->cs = zcalloc(thread->connections * sizeof(connection));
    connection *c = thread->cs;
    for (int i = 0; i < thread->connections; i++, c++) {
        c->thread = thread;
        if (i == -1) {
            c->http = true;
            http_addr(&(c->host), &c->port);
        }else {
            c->http = false;

            c->host = cfg.host;
            c->port = cfg.port; 
        }
        c->request = NULL;
        c->length = c->written = 0;
        connect_socket(thread, c);
    }
    aeEventLoop *loop = thread->loop;
    aeCreateTimeEvent(loop, RECORD_INTERVAL_MS, record_rate, thread, NULL);
    aeCreateTimeEvent(loop, REARM_WRITEABLE_MS, rearm_writeable, thread, NULL);
    
    aeMain(loop);
    aeDeleteEventLoop(loop);
    zfree(thread->cs);

    lua_close(thread->L);

    return NULL;
}

int main() {
#ifdef HAVE_WSAPOLL
    /* Windows:在使用 Winsock2 前必须初始化 */
    WSADATA wsaData;
    if (WSAStartup(MAKEWORD(2, 2), &wsaData) != 0) {
        printf("WSAStartup failed: %d\n", WSAGetLastError());
        return -1;
    }
#endif

    if (init_config(&cfg) == false) {
        printf("invalid config param, config key muse be string, check please.\n");
        return -1;
    }
    if (!cfg.connections || cfg.connections < cfg.threads) {
        printf("number of connections must be >= threads\n");
        return -1;
    }

    statistics.latency  = stats_alloc(cfg.timeout * 1000);
    thread *threads     = zcalloc(cfg.threads * sizeof(thread));
    for (int i = 0; i < cfg.threads; i++) {
        thread *t      = &threads[i];
        t->identify    = i + 1;
        t->loop        = aeCreateEventLoop(10 + cfg.connections * 3);
        t->connections = cfg.connections / cfg.threads;

        t->L = create_luastate();

        if (pthread_create(&t->thread, NULL, &thread_main, t)) {
            printf("create thread failed!");
            exit(2);
        }
    }

#ifdef HAVE_WSAPOLL
    /* Windows:用 signal 替代 sigaction(sigaction 在 MinGW 不完整) */
    signal(SIGINT, handler);
#else
    struct sigaction sa = {
        .sa_handler = handler,
        .sa_flags   = 0,
    };

    sigfillset(&sa.sa_mask);
    sigaction(SIGINT, &sa, NULL);
#endif

    printf("Running %"PRIu64"s test skynet\n", cfg.duration);
    printf("  %"PRIu64" threads and %"PRIu64" connections\n", cfg.threads, cfg.connections);

    uint64_t start    = time_us();
    uint64_t reqcount = 0;
    uint64_t complete = 0;
    uint64_t bytes    = 0;
    errors errors     = { 0 };

    /* 每秒轮询:收到 Ctrl+C(stop)或全部线程业务用例跑完(done_threads)
       均可提前结束,不再死等完整 duration;配置时长仅作为上限 */
    for (uint64_t i = 0; i < cfg.duration && !stop; i++) {
        sleep(1);
        if (done_threads >= cfg.threads) break;
    }
    stop = 1;
    if (done_threads > 0) {
        printf("all threads tasks done, early stop after %llu s (configured %llu s)\n",
               (unsigned long long)((time_us() - start) / 1000000ULL),
               (unsigned long long)cfg.duration);
    }

    for (int i = 0; i < cfg.threads; i++) {
        thread *t = &threads[i];
        pthread_join(t->thread, NULL);
        reqcount += t->reqcount;
        complete += t->complete;
        bytes    += t->bytes;

        errors.connect += t->errors.connect;
        errors.read    += t->errors.read;
        errors.write   += t->errors.write;
        errors.timeout += t->errors.timeout;
    }
    uint64_t runtime_us = time_us() - start;
    double runtime_s   = runtime_us / 1000000.0;
    double req_per_s   = reqcount   / runtime_s;
    double res_per_s   = complete   / runtime_s;
    double bytes_per_s = bytes      / runtime_s;

    printf("Running %"PRIu64"s test skynet\n", cfg.duration);
    printf("  %"PRIu64" threads and actually %"PRIu64" connections\n", cfg.threads, statistics.latency->connects);
    print_stats_header();
    print_stats("Latency", statistics.latency);

    printf("  %"PRIu64" requests %"PRIu64" responses in %.2f ms, %.2f kb read\n", reqcount, complete, runtime_us/1000.0, bytes/1024.0);
    if (errors.connect || errors.read || errors.write || errors.timeout) {
        printf("  Socket errors: connect %d, read %d, write %d, timeout %d\n",
               errors.connect, errors.read, errors.write, errors.timeout);
    }

    printf("Requests/sec: %9.2f\n", req_per_s);
    printf("Responses/sec: %9.2f\n", res_per_s);
    printf("Transfer/sec: %10.2f kb\n", bytes_per_s/1024.0);

#ifdef HAVE_WSAPOLL
    WSACleanup();
#endif
    /* 强制退出进程:main 正常 return 后 MinGW CRT/DLL(libwinpthread)清理阶段可能死锁,
     * 导致统计已打印但进程残留(需手动 taskkill),阻塞下次运行时 wrk.exe 文件锁。
     * 压测结果已输出完毕,此处直接终止进程,绕过 DLL 清理。 */
    fflush(NULL);
    ExitProcess(0);
    return 0;
}

static void print_stats_header() {
    printf("  Thread Stats%10s%10s%10s\n", "Avg", "Min", "Max");
}

static void print_stats(char *name, stats *stats) {
    uint64_t min = stats->min;
    uint64_t max = stats->max;
    double mean  = stats_mean(stats);

    printf("    %-10s", name);
    printf("    %.2f ms", mean/1000);
    printf("    %.2f ms", min/1000.0);
    printf("    %.2f ms\n", max/1000.0);
}