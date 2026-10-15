/* Windows WSAPoll() based ae.c module
 *
 * 用 Winsock2 的 WSAPoll 替代 Linux epoll,实现 Redis ae 事件循环后端。
 * WSAPoll 在 Windows Vista 之后可用,API 形态与 POSIX poll 类似,
 * 因此映射简单:fd -> {fd, events, revents}。
 *
 * 注意:Windows 套接字描述符不是小整数(可能很大),但 aeEventLoop
 * 用 fd 作为 events[] 索引,所以这里依然按 fd 索引访问。
 *
 * Copyright (c) 2026, LuaYaCe Windows 移植
 * 基于 ae_epoll.c 改造。原 ae_epoll.c 版权归 Salvatore Sanfilippo 所有。
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *   * Redistributions of source code must retain the above copyright notice.
 *   * Redistributions in binary form must reproduce the above copyright notice.
 */

#ifdef HAVE_WSAPOLL

#include <winsock2.h>
#include <ws2tcpip.h>
#include <mswsock.h>

/* fd -> slot 开放寻址哈希表大小,覆盖 Windows 套接字句柄范围 */
#define FD_MAP_SIZE 65536

/* fd 与 slot 的映射条目,fd == -1 表示空槽 */
typedef struct {
    int fd;
    int slot;
} fd_slot_entry;

typedef struct aeApiState {
    WSAPOLLFD *events;          /* pollfd 数组,按 slot 紧凑索引(不再按 fd) */
    fd_slot_entry *fd_map;      /* fd -> slot 开放寻址哈希表 */
    int *slot_to_fd;            /* slot -> fd 逆映射,-1 表示空槽 */
} aeApiState;

static int aeApiCreate(aeEventLoop *eventLoop) {
    aeApiState *state = zmalloc(sizeof(aeApiState));
    int i;
    if (!state) return -1;
    state->events = zmalloc(sizeof(WSAPOLLFD) * eventLoop->setsize);
    state->fd_map = zmalloc(sizeof(fd_slot_entry) * FD_MAP_SIZE);
    state->slot_to_fd = zmalloc(sizeof(int) * eventLoop->setsize);
    if (!state->events || !state->fd_map || !state->slot_to_fd) {
        zfree(state->events);
        zfree(state->fd_map);
        zfree(state->slot_to_fd);
        zfree(state);
        return -1;
    }
    memset(state->events, 0, sizeof(WSAPOLLFD) * eventLoop->setsize);
    for (i = 0; i < FD_MAP_SIZE; i++) {
        state->fd_map[i].fd = -1;
        state->fd_map[i].slot = -1;
    }
    for (i = 0; i < eventLoop->setsize; i++)
        state->slot_to_fd[i] = -1;
    eventLoop->apidata = state;
    return 0;
}

static int aeApiResize(aeEventLoop *eventLoop, int setsize) {
    aeApiState *state = eventLoop->apidata;
    int i;
    state->events = zrealloc(state->events, sizeof(WSAPOLLFD) * setsize);
    state->slot_to_fd = zrealloc(state->slot_to_fd, sizeof(int) * setsize);
    if (setsize > eventLoop->setsize) {
        memset(state->events + eventLoop->setsize, 0,
               sizeof(WSAPOLLFD) * (setsize - eventLoop->setsize));
        for (i = eventLoop->setsize; i < setsize; i++)
            state->slot_to_fd[i] = -1;
    }
    return 0;
}

static void aeApiFree(aeEventLoop *eventLoop) {
    aeApiState *state = eventLoop->apidata;
    zfree(state->events);
    zfree(state->fd_map);
    zfree(state->slot_to_fd);
    zfree(state);
    eventLoop->apidata = NULL;
}

/* 查找 fd 对应的 slot,找不到返回 -1(非 static,供 ae.c 用) */
int aeWsapollFdToSlot(aeEventLoop *eventLoop, int fd) {
    aeApiState *state = eventLoop->apidata;
    int i;
    int start = (unsigned)fd % FD_MAP_SIZE;
    for (i = 0; i < FD_MAP_SIZE; i++) {
        int probe = (start + i) % FD_MAP_SIZE;
        if (state->fd_map[probe].fd == -1) return -1;
        if (state->fd_map[probe].fd == fd) return state->fd_map[probe].slot;
    }
    return -1;
}

/* 为 fd 分配新 slot,失败返回 -1 */
static int aeWsapollAllocSlot(aeEventLoop *eventLoop, int fd) {
    aeApiState *state = eventLoop->apidata;
    int i, slot = -1;
    int start;
    for (i = 0; i < eventLoop->setsize; i++) {
        if (state->slot_to_fd[i] == -1) { slot = i; break; }
    }
    if (slot == -1) return -1;
    start = (unsigned)fd % FD_MAP_SIZE;
    for (i = 0; i < FD_MAP_SIZE; i++) {
        int probe = (start + i) % FD_MAP_SIZE;
        if (state->fd_map[probe].fd == -1) {
            state->fd_map[probe].fd = fd;
            state->fd_map[probe].slot = slot;
            state->slot_to_fd[slot] = fd;
            state->events[slot].fd = fd;
            state->events[slot].events = 0;
            state->events[slot].revents = 0;
            return slot;
        }
    }
    return -1;
}

/* 释放 fd 占用的 slot */
static void aeWsapollFreeSlot(aeEventLoop *eventLoop, int fd) {
    aeApiState *state = eventLoop->apidata;
    int i;
    int start = (unsigned)fd % FD_MAP_SIZE;
    for (i = 0; i < FD_MAP_SIZE; i++) {
        int probe = (start + i) % FD_MAP_SIZE;
        if (state->fd_map[probe].fd == -1) return;
        if (state->fd_map[probe].fd == fd) {
            int slot = state->fd_map[probe].slot;
            state->fd_map[probe].fd = -1;
            state->fd_map[probe].slot = -1;
            if (slot >= 0 && slot < eventLoop->setsize) {
                state->slot_to_fd[slot] = -1;
                /* fd 置 -1(WSAPoll 忽略负 fd 项),0 可能与真实句柄值冲突 */
                state->events[slot].fd = -1;
                state->events[slot].events = 0;
                state->events[slot].revents = 0;
            }
            return;
        }
    }
}

static int aeApiAddEvent(aeEventLoop *eventLoop, int fd, int mask) {
    aeApiState *state = eventLoop->apidata;
    int slot = aeWsapollFdToSlot(eventLoop, fd);
    if (slot == -1) {
        slot = aeWsapollAllocSlot(eventLoop, fd);
        if (slot == -1) return -1;
    }
    /* 合并已有掩码(events[slot].mask 由 ae.c 维护),计算 events 字段 */
    mask |= eventLoop->events[slot].mask;
    short pollevents = 0;
    if (mask & AE_READABLE) pollevents |= (POLLRDNORM | POLLIN);
    if (mask & AE_WRITABLE) pollevents |= (POLLWRNORM | POLLOUT);

    state->events[slot].fd = fd;
    state->events[slot].events = pollevents;
    state->events[slot].revents = 0;
    return 0;
}

static void aeApiDelEvent(aeEventLoop *eventLoop, int fd, int delmask) {
    aeApiState *state = eventLoop->apidata;
    int slot = aeWsapollFdToSlot(eventLoop, fd);
    if (slot == -1) return;

    /* 移除指定掩码后剩余的掩码(events[slot].mask 是旧值,ae.c 随后更新) */
    int mask = eventLoop->events[slot].mask & (~delmask);
    short pollevents = 0;
    if (mask & AE_READABLE) pollevents |= (POLLRDNORM | POLLIN);
    if (mask & AE_WRITABLE) pollevents |= (POLLWRNORM | POLLOUT);

    state->events[slot].events = pollevents;
    state->events[slot].revents = 0;
    /* 掩码归零时释放 slot,保持 pollfd 数组紧凑 */
    if (mask == 0) {
        aeWsapollFreeSlot(eventLoop, fd);
    }
}

static int aeApiPoll(aeEventLoop *eventLoop, struct timeval *tvp) {
    aeApiState *state = eventLoop->apidata;
    int numevents = 0;

    /* WSAPoll 参数:
     *   fds       -> pollfd 数组
     *   nfds      -> 数组长度(整段遍历,events==0 的项会被跳过)
     *   timeout   -> 毫秒,-1 表示永久等待 */
    int timeout = tvp ? (int)(tvp->tv_sec * 1000 + tvp->tv_usec / 1000) : -1;

    /* 由于 setsize 可能远大于活跃 fd,整段 poll 会浪费 CPU。
     * 但 wrk 的 setsize = 10 + connections*3,通常较小(几百个),
     * 直接全量 poll 性能可接受。如需优化可改用紧凑数组方案。 */
    int retval = WSAPoll(state->events, eventLoop->setsize, timeout);

    if (retval > 0) {
        int j;
        for (j = 0; j < eventLoop->setsize && numevents < retval; j++) {
            WSAPOLLFD *pfd = &state->events[j];
            if (pfd->fd == 0 && pfd->events == 0) continue;  /* 未使用槽位 */
            short re = pfd->revents;
            if (re == 0) continue;

            int mask = 0;
            if (re & (POLLRDNORM | POLLIN))  mask |= AE_READABLE;
            if (re & (POLLWRNORM | POLLOUT)) mask |= AE_WRITABLE;
            /* POLLERR/POLLHUP 对应可写以触发 socket 错误处理 */
            if (re & POLLERR) mask |= AE_WRITABLE;
            if (re & POLLHUP) mask |= AE_WRITABLE;

            if (mask == 0) continue;

            eventLoop->fired[numevents].fd = pfd->fd;
            eventLoop->fired[numevents].mask = mask;
            numevents++;
            /* 清理 revents 供下次使用 */
            pfd->revents = 0;
        }
    }
    /* retval == SOCKET_ERROR(-1)时返回 0,等同无事件 */
    return numevents;
}

static char *aeApiName(void) {
    return "wsapoll";
}

#endif /* HAVE_WSAPOLL */
