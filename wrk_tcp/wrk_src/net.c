// Copyright (C) 2013 - Will Glozer.  All rights reserved.

#include <errno.h>
#include "net.h"

/* Windows 兼容:
 *   read/write 仅用于 fd 上的 I/O,Windows socket 必须用 recv/send
 *   ioctl(FIONREAD) 在 Windows 用 ioctlsocket 实现
 *   unistd.h/sys/ioctl.h 是 POSIX 头,Windows 不需要(net.h 已 include winsock) */
#ifndef HAVE_WSAPOLL
#include <unistd.h>
#include <sys/ioctl.h>
#endif

status sock_connect(connection *c, char *host) {
    return OK;
}

status sock_close(connection *c) {
    return OK;
}

status sock_read(connection *c, size_t *n) {
#ifdef HAVE_WSAPOLL
    /* Windows:用 recv 替代 read,flag=0 */
    ssize_t r = recv(c->fd, (char *)c->buf, sizeof(c->buf), 0);
    if (r == SOCKET_ERROR) {
        int err = WSAGetLastError();
        *n = 0;
        /* WSAEWOULDBLOCK 表示无数据可读,等同 POSIX EAGAIN */
        return (err == WSAEWOULDBLOCK) ? RETRY : ERROR;
    }
    *n = (size_t) r;
    return OK;
#else
    ssize_t r = read(c->fd, c->buf, sizeof(c->buf));
    *n = (size_t) r;
    return r >= 0 ? OK : ERROR;
#endif
}

status sock_write(connection *c, void *buf, size_t len, size_t *n) {
#ifdef HAVE_WSAPOLL
    /* Windows:用 send 替代 write */
    ssize_t r = send(c->fd, (const char *)buf, (int)len, 0);
    if (r == SOCKET_ERROR) {
        int err = WSAGetLastError();
        *n = 0;
        return (err == WSAEWOULDBLOCK) ? RETRY : ERROR;
    }
    *n = (size_t) r;
    return OK;
#else
    ssize_t r;
    if ((r = write(c->fd, buf, len)) == -1) {
        switch (errno) {
            case EAGAIN: return RETRY;
            default:     return ERROR;
        }
    }

    *n = (size_t) r;
    return OK;
#endif
}

size_t sock_readable(connection *c) {
#ifdef HAVE_WSAPOLL
    /* Windows:用 ioctlsocket(FIONREAD) 获取可读字节数 */
    u_long bytes_avail = 0;
    int rc = ioctlsocket(c->fd, FIONREAD, &bytes_avail);
    return rc == SOCKET_ERROR ? 0 : (size_t)bytes_avail;
#else
    int n;
    int rc;
    rc = ioctl(c->fd, FIONREAD, &n);
    return rc == -1 ? 0 : (size_t)n;
#endif
}
