// From hxcpp
#include <hx/Thread.h>

#include <Sound.h>
#include "Audio.h"


namespace nme
{

void clLock();
void clUnlock();

struct OpenChannel
{
   OpenChannel(SoundChannel *inChannel=0, bool inIsAsync=0)
     : channel(inChannel), isAsync(inIsAsync) { }

   bool operator==(const OpenChannel &inOther) const { return channel==inOther.channel; }
   bool operator==(SoundChannel *inCannel) const { return channel==inCannel; }

   SoundChannel *channel;
   bool         isAsync;
};

QuickVec<OpenChannel> sgOpenChannels;
bool clIsInit = false;
bool clSoundSuspended = false;

void clUpdateAsyncChannelsLocked()
{
   if (clSoundSuspended)
      return;

   for(int i=0;i<sgOpenChannels.size();i++)
       if (sgOpenChannels[i].isAsync)
           sgOpenChannels[i].channel->asyncUpdate();
}


void clUpdateAsyncChannels()
{
   if (!clIsInit)
      return;
   clLock();
   clUpdateAsyncChannelsLocked();
   clUnlock();
}


bool asyncIsShutdown = false;


#ifdef HX_WINDOWS

HxMutex asyncSoundMutex;

void clInit(bool inFirst, bool inIsAsync)
{
   #ifdef NME_OPENAL
     #error "Async openal update loop not implemented"
   #endif
}


void clPingLocked() { }

void clLock()
{
   asyncSoundMutex.Lock();
}


void clUnlock()
{
   asyncSoundMutex.Unlock();
}


#else

pthread_mutex_t asyncSoundMutex;
pthread_t  asyncSoundThread;
pthread_cond_t asyncSoundWake = PTHREAD_COND_INITIALIZER;
bool asyncSoundMainLoopStarted = false;
bool asyncSoundWaiting = false;

void *asyncSoundMainLoop(void *)
{
   pthread_mutex_lock(&asyncSoundMutex);
   asyncSoundWaiting = true;
   while(!asyncIsShutdown)
   {
      clUpdateAsyncChannelsLocked();

      if (clSoundSuspended || sgOpenChannels.size()==0)
      {
         // Give up the mutex until we get a signal
         pthread_cond_wait( &asyncSoundWake, &asyncSoundMutex );
      }
      else
      {
         struct timeval now;
         gettimeofday(&now,NULL);

         struct timespec timeToWait;
         timeToWait.tv_sec = now.tv_sec;
         timeToWait.tv_nsec = (now.tv_usec+250000)*1000;
         if (timeToWait.tv_nsec>=1000000000)
         {
            timeToWait.tv_nsec-=1000000000;
            timeToWait.tv_sec++;
         }

         // Give up the mutex until we get a signal, or timeout
         pthread_cond_timedwait( &asyncSoundWake, &asyncSoundMutex, &timeToWait );
      }

   }
   asyncSoundWaiting = false;
   pthread_mutex_unlock(&asyncSoundMutex);
   return 0;
}

void clInit(bool inFirst, bool inIsAsync)
{
   if (inFirst)
   {
      pthread_mutexattr_t mta;
      pthread_mutexattr_init(&mta);
      pthread_mutexattr_settype(&mta, PTHREAD_MUTEX_RECURSIVE);
      pthread_mutex_init(&asyncSoundMutex,&mta);
   }

   #ifdef NME_OPENAL
   if (inIsAsync && !asyncSoundMainLoopStarted)
   {
      asyncSoundMainLoopStarted = true;
      pthread_create(&asyncSoundThread, 0,  asyncSoundMainLoop, 0 );
   }
   #endif
}


void clPingLocked()
{
   if (asyncSoundWaiting)
      pthread_cond_signal(&asyncSoundWake);
}


void clLock()
{
   pthread_mutex_lock(&asyncSoundMutex);
}


void clUnlock()
{
   pthread_mutex_unlock(&asyncSoundMutex);
}


#endif


// --- Manage async sound updating --------------------------------

void clShutdown()
{
   clLock();
   sgOpenChannels.resize(0);
   asyncIsShutdown = true;
   clPingLocked();
   clUnlock();
}


void clResumeAllChannels()
{
   LOG_SOUND("clResumeAllChannels !\n");
   if (!clIsInit)
      return;
   clLock();
   for(int i = 0; i < sgOpenChannels.size(); i++)
   {
      if(!sgOpenChannels[i].channel->isComplete())
         sgOpenChannels[i].channel->resume();
   }
   clSoundSuspended = false;
   clPingLocked();
   clUnlock();
}


void clSuspendAllChannels()
{
   LOG_SOUND("clSuspendAllChannels !\n");
   if (!clIsInit)
      return;
   clLock();
   for(int i = 0; i<sgOpenChannels.size(); i++)
      sgOpenChannels[i].channel->suspend();
   clSoundSuspended = true;
   clUnlock();
}


void clAddChannel(SoundChannel *inChannel,bool inIsAsync)
{
   clInit(!clIsInit, inIsAsync);
   clIsInit = true;

   LOG_SOUND("Add channel filler %p/%d", inChannel,inIsAsync);

   clLock();
   sgOpenChannels.push_back( OpenChannel(inChannel,inIsAsync) );
   if (inIsAsync)
      clPingLocked();
   clUnlock();
}

void clRemoveChannel(SoundChannel *inChannel)
{
   LOG_SOUND("Remove channel filler %p", inChannel);
   clLock();
   sgOpenChannels.qremove(inChannel);
   clUnlock();
}


}


