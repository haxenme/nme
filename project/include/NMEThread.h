#ifndef NME_THREAD_H
#define NME_THREAD_H

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

struct NmeMutex
{
   pthread_mutex_t mutex;

   NmeMutex()
   {
      pthread_mutexattr_t mta;
      pthread_mutexattr_init(&mta);
      pthread_mutexattr_settype(&mta, PTHREAD_MUTEX_RECURSIVE);
      pthread_mutex_init(&mutex,&mta);
   }
   ~NmeMutex()
   {
      pthread_mutex_destroy(&mutex);
   }
   void lock()
   {
      pthread_mutex_lock(&mutex); 
   }

   void unlock()
   {
      pthread_mutex_unlock(&mutex); 
   }
};


#else
typedef DWORD ThreadId;


struct NmeMutex
{
   HANDLE mutex;

   NmeMutex()
   {
      mutex  = CreateMutex(0, false, 0);
   }
   ~NmeMutex()
   {
      CloseHandle(mutex);
   }
   void lock()
   {
      WaitForSingleObject( mutex, INFINITE);
   }

   void unlock()
   {
      ReleaseMutex(mutex);
   }
};




#endif

ThreadId GetThreadId();
bool IsMainThread();
void SetMainThread();

struct NmeAutoMutex
{
   NmeMutex &mutex;
   NmeAutoMutex(NmeMutex &inMutex) : mutex(inMutex)
   {
      mutex.lock();
   }
   ~NmeAutoMutex()
   {
     mutex.unlock();
   }
};


}

#endif

