#include "script.h"
/*
lua stack
正数相对于栈底
负数相对于栈顶
 3 | | -1
 2 | | -2
 1 | | -3
*/

lua_State *create_luastate() {
    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    return L;
}

void script_start(lua_State *L, uint16_t identify, uint64_t connections) {
    int load_ret = luaL_dofile(L, "./lualib/loader.lua");
    if (load_ret != LUA_OK) {
        const char *err = lua_tostring(L, -1);
        printf("loader.lua load error, code:%d, msg:%s\n", load_ret, err ? err : "(null)");
        lua_pop(L, 1);
        return;
    }
    if (!lua_istable(L, -1)) {
        printf("loader.lua did not return a table, got %s\n", lua_typename(L, lua_type(L, -1)));
        lua_pop(L, 1);
        return;
    }
    lua_getfield(L, -1, "init");
    lua_pushinteger(L, identify);
    lua_pushinteger(L, connections);

    int ret = lua_pcall(L,2,0,0);
	if (ret == LUA_OK){
		lua_setglobal(L, "main");
	}else {
		/* LUA_ERRRUN(2)/LUA_ERRSYNTAX(3) 等错误时,Lua 栈顶有错误消息 */
		const char *err = lua_tostring(L, -1);
		printf("script_start error, code:%d, msg:%s\n", ret, err ? err : "(null)");
		lua_pop(L, 1);  /* 弹出错误对象,保持栈平衡 */
	}
}

void script_connected(lua_State *L, int fd) {
    lua_getglobal(L, "main");
    lua_getfield(L, -1, "connected"); 
    lua_pushinteger(L, fd);
    /* pcall 捕获 Lua 层 connected 抛错并打印,否则 client 初始化失败无任何日志,
       只能看到下游的 no client fd,无法定位真正抛错点 */
    int ret = lua_pcall(L,1,0,0);
    if (ret != LUA_OK) {
        const char *err = lua_tostring(L, -1);
        printf("script_connected fd:%d error, code:%d, msg:%s\n", fd, ret, err ? err : "(null)");
        lua_pop(L, 1); /* 弹出错误消息,保持栈平衡 */
    }
	lua_pop(L, 1); /* 弹出 main 表 */
}

static void *
get_buffer(lua_State *L, int index, int *sz) {
	void *buffer = NULL;
	switch(lua_type(L, index)) {
        const char * str;
        size_t len;
	case LUA_TUSERDATA:
	case LUA_TLIGHTUSERDATA:
		buffer = lua_touserdata(L,index);
		*sz = luaL_checkinteger(L,index+1);
		break;
	// case LUA_TTABLE:
	// 	// concat the table as a string
	// 	len = count_size(L, index);
	// 	buffer = skynet_malloc(len);
	// 	concat_table(L, index, buffer, len);
	// 	*sz = (int)len;
	// 	break;
	default:
		str =  luaL_checklstring(L, index, &len);
		buffer = malloc(len);
		memcpy(buffer, str, len);
		*sz = (int)len;
		break;
	}
	return buffer;
}

void script_http_writeable(lua_State *L, int fd, char **buf, int *sz) {
    lua_getglobal(L, "main");
    lua_getfield(L, -1, "http_writeable"); 
    lua_pushinteger(L, fd);
    lua_pcall(L,1,2,0);
	*buf = get_buffer(L, 2, sz);
    lua_pop(L,3);
}

void script_writeable(lua_State *L, int fd, char **buf, int *sz) {
    lua_getglobal(L, "main");
    lua_getfield(L, -1, "writeable"); 
    lua_pushinteger(L, fd);
    if (lua_pcall(L,1,2,0) != 0) {
        /* 与 script_connected 同样的静默吞错修复:
         * pcall 失败时栈顶为错误消息,c->request 取到 NULL,
         * AE_WRITABLE 被移除,send_queue 里的包永久发不出去 */
        const char *msg = lua_tostring(L, -1);
        fprintf(stderr, "script_writeable fd:%d error, msg:%s\n", fd, msg ? msg : "unknown");
        fflush(stderr);
        lua_pop(L, 3);
        *buf = NULL;
        *sz = 0;
        return;
    }
	*buf = get_buffer(L, 2, sz);
    lua_pop(L,3);
}

int script_readable(lua_State *L, int fd, unsigned char *buffer, int sz, int *readover) {
    lua_getglobal(L, "main");
    lua_getfield(L, -1, "readable"); 
    lua_pushinteger(L, fd);
	lua_pushlightuserdata(L, buffer);
    lua_pushinteger(L, sz);
    lua_pcall(L,3,2,0);

    int result = luaL_checkinteger(L, -1);
    *readover = luaL_checkinteger(L, -2);

    lua_pop(L,3);

    return result;
}

uint64_t script_delay(lua_State *L, int fd) {
    lua_getglobal(L, "main");
    lua_getfield(L, -1, "delay"); 
    lua_pushinteger(L, fd);
    lua_pcall(L,1,1,0);
    uint64_t delay = lua_tonumber(L, -1);
    lua_pop(L, 2);

    return delay;
}

void script_heartbeat(lua_State *L, int fd) {
    lua_getglobal(L, "main");
    lua_getfield(L, -1, "heartbeat"); 
    lua_pushinteger(L, fd);
    lua_pcall(L,1,0,0);
    lua_pop(L, 1);
}

void script_response(lua_State *L, int fd, int status, buffer *headers, buffer *body) {
    lua_getglobal(L, "main");
    lua_getfield(L, -1, "http_readable"); 
    lua_pushinteger(L, fd);
    lua_pushinteger(L, status);
    lua_pushlstring(L, body->buffer, body->cursor - body->buffer);
    lua_call(L, 3, 0);

    buffer_reset(body);
}

void buffer_append(buffer *b, const char *data, size_t len) {
    size_t used = b->cursor - b->buffer;
    while (used + len + 1 >= b->length) {
        b->length += 1024;
        b->buffer  = realloc(b->buffer, b->length);
        b->cursor  = b->buffer + used;
    }
    memcpy(b->cursor, data, len);
    b->cursor += len;
}

void buffer_reset(buffer *b) {
    b->cursor = b->buffer;
}

char *buffer_pushlstring(lua_State *L, char *start) {
    char *end = strchr(start, 0);
    lua_pushlstring(L, start, end - start);
    return end + 1;
}
