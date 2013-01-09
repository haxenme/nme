#ifndef NME_THREAD_H
#define NME_THREAD_H

#include <pthread.h>

namespace nme
{
typedef pthread_t ThreadId;

ThreadId GetThreadId();
bool IsMainThread();
void SetMainThread();
}

#endif

