
#ifndef __NME_NEKO_THREAD_ACCESS_H
#define __NME_NEKO_THREAD_ACCESS_H



#ifdef NEKO_WINDOWS
#       include <windows.h>
        typedef HANDLE vlock;
#else
#       include <pthread.h>
#       include <sys/time.h>
        typedef struct _vlock {
                pthread_mutex_t lock;
                pthread_cond_t cond;
                int counter;
        } *vlock;
#endif

typedef struct _tqueue {
        value msg;
        struct _tqueue *next;
} tqueue;

typedef struct {
        tqueue *first;
        tqueue *last;
#       ifdef NEKO_WINDOWS
        CRITICAL_SECTION lock;
        HANDLE wait;
#       else
        pthread_mutex_t lock;
        pthread_cond_t wait;
#       endif
} vdeque;

typedef struct {
#       ifdef NEKO_WINDOWS
        DWORD tid;
#       else
        pthread_t phandle;
#       endif
        value v;
        vdeque q;
} vthread;

#define val_thread(t)   ((vthread*)val_data(t))


void thread_send( value vt, value msg );

#endif
