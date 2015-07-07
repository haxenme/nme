#ifndef NME_THREAD_H
#define NME_THREAD_H

#include <hx/Thread.h>

#ifndef HX_WINDOWS
#include <pthread.h>
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

typedef MyMutex NmeMutex;

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


}

#endif

