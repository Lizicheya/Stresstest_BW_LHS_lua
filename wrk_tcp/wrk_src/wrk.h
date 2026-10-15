#ifndef WRK_H
#define WRK_H

#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <stdlib.h>
#include <inttypes.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

/* 必须先 include config.h,才能用 HAVE_WSAPOLL 宏选择平台头 */
#include "config.h"

/* 平台相关头文件:
 *   Windows:Winsock2 + winpthreads(MinGW-w64 自带)
 *   其他:原 POSIX 头 */
#ifdef HAVE_WSAPOLL
/* stdint.h 必须在 winsock2 之前,ws2tcpip.h 用了 uint32_t 等 */
#include <stdint.h>
/* winsock2.h 必须在 windows.h 之前包含,以避免 winsock.h 冲突 */
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#include <mswsock.h>
#include <signal.h>
#include <time.h>            /* mingw 提供 time() 等 */

/* MinGW-w64 自带 winpthreads,提供 pthread API 兼容 */
#include <pthread.h>
#include <io.h>              /* mingw 的 _open 等 */
#include <process.h>        /* _getpid */

/* POSIX 兼容宏:
 *   Windows errno.h 已定义 EINPROGRESS(112)/EAGAIN(11),
 *   需先 #undef 清除再重定义为 WSAEWOULDBLOCK,使 socket API 行为一致 */
#undef EINPROGRESS
#undef EAGAIN
#define EINPROGRESS      WSAEWOULDBLOCK  /* 非阻塞 connect 返回此码 */
#define EAGAIN           WSAEWOULDBLOCK

/* windows.h 把 ERROR 定义为 0,会与 net.h 的枚举 ERROR 冲突,
 * 此处 #undef 让 net.h 的枚举可用。wrk 代码本身不依赖 Windows ERROR 宏 */
#undef ERROR

/* Windows 没有差分 sleep 函数,使用 Sleep(ms) */
#define sleep(sec)       Sleep((sec) * 1000)

/* fcntl O_NONBLOCK 替代:用 ioctlsocket(FIONBIO) */
#define F_GETFL 0
#define F_SETFL 0
#define O_NONBLOCK 1
#define fcntl(fd, cmd, arg) wrk_set_nonblock(fd)  /* 简化为单参数版本 */

#else
/* POSIX 平台 */
#include <sys/time.h>
#include <pthread.h>
#include <netdb.h>
#include <sys/types.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <fcntl.h>
#include <sys/errno.h>
#include <unistd.h>
#include <signal.h>
#endif

#include "config.h"
#include "zmalloc.h"
#include "ae.h"
#include "stats.h"
#include "http_parser.h"

#define RECVBUF  8192

#define MAX_THREAD_RATE_S   10000000
#define HEARTBEAT_INTERVAL_MS  20
#define RECORD_INTERVAL_MS  100

typedef struct {
    uint64_t  connections;
    uint64_t  duration;
    uint64_t  threads;
    uint64_t  timeout;
    bool delay;
    bool latency;
    char *host;
    int  port;
    char *url;
    bool debug;   /* 调试日志开关:从 config.lua 的 debug 字段读取,false 时关闭高频诊断日志 */
} config;

typedef struct {
    char  *buffer;
    size_t length;
    char  *cursor;
} buffer;

typedef struct {
    pthread_t thread;
    aeEventLoop *loop;
    uint16_t identify;
    uint64_t connections;
    uint64_t reqcount;
    uint64_t complete;
    uint64_t requests;
    uint64_t bytes;
    uint64_t start;
    lua_State *L;
    errors errors;
    struct connection *cs;
    int task_done; /* 本线程业务用例是否全部完成(report_done 上报时防重复计数) */
} thread;

typedef struct connection{
    thread *thread;
    http_parser parser;
    int fd;
    int connecting; /* 非阻塞 connect 尚未完成标记,防止 rearm_writeable 抢占 socket_connected 回调 */
    uint64_t start;
    char *request;
    int length;
    int written;
    bool http;
    char *host;
    int  port;
    buffer headers;
    buffer body;
    unsigned char buf[RECVBUF];
} connection;

/* Windows 工具函数声明 */
#ifdef HAVE_WSAPOLL
/* 设置非阻塞模式(ioctlsocket FIONBIO),返回原 fcntl 风格结果 */
static inline int wrk_set_nonblock(int fd) {
    u_long mode = 1;
    return ioctlsocket(fd, FIONBIO, &mode);
}
#endif

#endif /* WRK_H */
