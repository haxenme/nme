#include <NMEThread.h>

namespace nme
{

ThreadId GetThreadId()
{
   #ifdef HX_WINDOWS
   return GetCurrentThreadId();
   #elif defined(EMSCRIPTEN)
   return 0;
   #else
   return pthread_self();
   #endif
}



static ThreadId sMainThread = 0;

void SetMainThread()
{
   sMainThread = GetThreadId();
}

bool IsMainThread()
{
   return sMainThread==GetThreadId();
}



volatile int gTaskId = 0;

// Workers  - stubs
#ifndef NME_WORKER_THREADS
int GetWorkerCount() { return 1; }
void RunWorkerTask( WorkerFunc inFunc, void *inData )
{
   gTaskId = 0;
   inFunc(0,inData);
}

// Workers  - implementation
#else

int sWorkerCount = 0;

volatile int gActiveThreads = 0;

#define MAX_NME_THREADS 4

#ifdef NME_PTHREADS
static NmeMutex sThreadPoolLock;
typedef pthread_cond_t ThreadPoolSignal;
inline void WaitThreadLocked(ThreadPoolSignal &ioSignal)
{
   pthread_cond_wait(&ioSignal, &sThreadPoolLock.mMutex);
}
#else
typedef HxSemaphore ThreadPoolSignal;
#endif

bool sThreadActive[MAX_NME_THREADS];
ThreadPoolSignal sThreadWake[MAX_NME_THREADS];
ThreadPoolSignal sThreadJobDone;

static WorkerFunc sThreadJob = 0;
static void *sThreadData = 0;

static THREAD_FUNC_TYPE SThreadLoop( void *inInfo )
{
   int threadId = (int)(size_t)inInfo;
   while(true)
   {
      // Wait ....
      #ifdef NME_PTHREADS
      {
         ThreadPoolAutoLock l(sThreadPoolLock);
         while( !sThreadActive[threadId] )
            WaitThreadLocked(sThreadWake[threadId]);
      }
      #else
      while( !sThreadActive[threadId] )
         sThreadWake[threadId].Wait();
      #endif

      // Run
      sThreadJob( threadId, sThreadData );

      // Signal
      sThreadActive[threadId] = false;
      if (HxAtomicDec(&gActiveThreads)==1)
      {
         #ifdef NME_PTHREADS
         NmeAutoMutex lock(sThreadPoolLock);
         pthread_cond_signal(&sThreadJobDone);
         #else
         sThreadJobDone.Set();
         #endif
      }
   }
   THREAD_FUNC_RET;
}



void initWorkers()
{
   sWorkerCount = MAX_NME_THREADS;

   #ifdef NME_PTHREADS
   pthread_cond_init(&sThreadJobDone,0);
   #endif

   for(int t=0;t<sWorkerCount;t++)
   {
      sThreadActive[t] = false;
      #ifdef NME_PTHREADS
      pthread_cond_init(&sThreadWake[inId],0);
      pthread_t result = 0;
      int created = pthread_create(&result,0,SThreadLoop, (void *)(size_t)(int)t);
      bool ok = created==0;
      #else
      bool ok = HxCreateDetachedThread(SThreadLoop, (void *)(size_t)(int)t);
      #endif
   }
}

int GetWorkerCount()
{
   if (!sWorkerCount)
      initWorkers();
   return sWorkerCount;
}

void RunWorkerTask( WorkerFunc inFunc, void *inData )
{
   gTaskId = 0;
   if (!sWorkerCount)
      initWorkers();

   gActiveThreads = sWorkerCount;
   sThreadJob = inFunc;
   sThreadData = inData;


   #ifdef NME_PTHREADS
   NmeAutoMutex lock(sThreadPoolLock);
   #endif

   for(int t=0;t<sWorkerCount;t++)
   {
      sThreadActive[t] = true;
      #ifdef NME_PTHREADNME_PTHREADS
      pthread_cond_signal(&sThreadWake[t]);
      #else
      sThreadWake[t].Set();
      #endif
   }

   #ifdef NME_PTHREADS
   while(gActiveThreads)
      WaitThreadLocked(sThreadJobDone);
   #else
   while(gActiveThreads)
      sThreadJobDone.Wait();
   #endif

   sThreadJob = 0;
   sThreadData = 0;
}

#endif


} // end namespace nme
