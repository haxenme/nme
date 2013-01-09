#include <NMEThread.h>

namespace nme
{

ThreadId GetThreadId()
{
   return pthread_self();
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


} // end namespace nmE
