#ifndef NME_THREAD_H
#define NME_THREAD_H

#include <hx/Thread.h>

#ifndef HX_WINDOWS
#include <pthread.h>
#define NME_PTHREADS
#else
#include <windows.h>
#undef min
#undef max
#endif

namespace nme
{

#ifndef HX_WINDOWS
typedef pthread_t ThreadId;
#else
typedef DWORD ThreadId;
#endif

ThreadId GetThreadId();
bool IsMainThread();
void SetMainThread();

#if !defined(HXCPP_HEADER_VERSION) || (HXCPP_HEADER_VERSION<330)
typedef MyMutex NmeMutex;
#else
typedef HxMutex NmeMutex;
#endif

struct NmeAutoMutex
{
   NmeMutex &mutex;
   NmeAutoMutex(NmeMutex &inMutex) : mutex(inMutex)
   {
      mutex.Lock();
   }
   ~NmeAutoMutex()
   {
     mutex.Unlock();
   }
};


extern volatile int gTaskId;
extern int GetWorkerCount();

inline int GetNextTask()
{
   #ifdef NME_WORKER_THREADS
   return HxAtomicInc(&gTaskId);
   #else
   return gTaskId++;
   #endif
}

typedef void (*WorkerFunc)(int inThreadId, void *inData);
void RunWorkerTask( WorkerFunc inFunc, void *inData );


}

#endif

