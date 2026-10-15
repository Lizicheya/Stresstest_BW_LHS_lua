#ifndef CONFIG_H
#define CONFIG_H

/* 平台事件循环后端选择:
 *   HAVE_KQUEUE  -> BSD/macOS kqueue
 *   HAVE_EPOLL   -> Linux epoll
 *   HAVE_WSAPOLL -> Windows WSAPoll(Vista+,Winsock2)
 */
#if defined(__FreeBSD__) || defined(__APPLE__)
#define HAVE_KQUEUE
#elif defined(__linux__)
#define HAVE_EPOLL
#elif defined(_WIN32)
#define HAVE_WSAPOLL
#endif

/* Windows 平台标识:用于在 ae.c / wrk.h / net.c / wrk.c 中条件编译 */
#ifdef HAVE_WSAPOLL
#define _WRK_WIN32 1
#endif

#endif /* CONFIG_H */
