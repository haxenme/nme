#if defined(HX_MACOS) || defined(IPHONE)
#include <OpenAL/al.h>
#include <OpenAL/alc.h>
#else
#include <AL/al.h>
#include <AL/alc.h>
#endif

#ifdef ANDROID

extern "C" {
  ALC_API void       ALC_APIENTRY alcSuspend(void);
  ALC_API void       ALC_APIENTRY alcResume(void);
}

#include <ByteArray.h>
#endif

#include <math.h>
#include <Sound.h>
#include <nme/QuickVec.h>
#include <Utils.h>
#include <Audio.h>
#include <NmeThread.h>
#include <unistd.h>
#include <sys/time.h>

typedef unsigned char uint8;


#define MAX_STREAM_BUFFER_SIZE (45000 * 4 * 400/1000)


namespace nme
{

// --- OpenAl implementation -----------------------

static ALCdevice  *sgDevice = 0;
static ALCcontext *sgContext = 0;
static QuickVec<intptr_t> sgOpenChannels;

bool openal_is_init = false;
bool openal_is_shutdown = false;

bool OpenALInit()
{
   //LOG_SOUND("Sound.mm OpenALInit()");
   if (openal_is_shutdown) return false;
   
   if (!openal_is_init)
   {
      openal_is_init = true;
      sgDevice = alcOpenDevice(0); // select the "preferred device"
      if (sgDevice)
      {
         sgContext=alcCreateContext(sgDevice,0);
         alcMakeContextCurrent(sgContext);
      }
      sgOpenChannels = QuickVec<intptr_t>();
   }
   return sgContext;
}

bool OpenALClose()
{
   if (openal_is_init && !openal_is_shutdown)
   {
      openal_is_shutdown = true;
      alcMakeContextCurrent(0);
      if (sgContext) alcDestroyContext(sgContext);
      if (sgDevice) alcCloseDevice(sgDevice);
   }
   return true;
}


// --- Manage async sound updating --------------------------------

QuickVec<SoundChannel *> sgAsyncSounds;
pthread_mutex_t asyncSoundMutex;
pthread_t  asyncSoundThread;
pthread_cond_t asyncSoundWake = PTHREAD_COND_INITIALIZER;
bool asyncSoundSuspended = false;
bool asyncSoundMainLoopStarted = false;
bool asyncSoundWaiting = false;

void *asyncSoundMainLoop(void *)
{
   pthread_mutex_lock(&asyncSoundMutex);
   asyncSoundWaiting = true;
   while(true)
   {
      if (asyncSoundSuspended || sgAsyncSounds.size()==0)
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

      for(int i=0;i<sgAsyncSounds.size();i++)
         sgAsyncSounds[i]->asyncUpdate();
   }
   asyncSoundWaiting = false;
   pthread_mutex_unlock(&asyncSoundMutex);
   return 0;
}

void asyncSoundPingLocked()
{
   if (asyncSoundWaiting)
      pthread_cond_signal(&asyncSoundWake);
}


void asyncSoundAdd(SoundChannel *inChannel)
{
   if (!asyncSoundMainLoopStarted)
   {
      asyncSoundMainLoopStarted = true;
      pthread_mutexattr_t mta;
      pthread_mutexattr_init(&mta);
      pthread_mutexattr_settype(&mta, PTHREAD_MUTEX_RECURSIVE);
      pthread_mutex_init(&asyncSoundMutex,&mta);

      pthread_create(&asyncSoundThread, 0,  asyncSoundMainLoop, 0 );
   }

   LOG_SOUND("Add channel filler %p", inChannel);
   pthread_mutex_lock(&asyncSoundMutex);
   sgAsyncSounds.push_back(inChannel);
   asyncSoundPingLocked();
   pthread_mutex_unlock(&asyncSoundMutex);
}

void asyncSoundRemove(SoundChannel *inChannel)
{
   LOG_SOUND("Remove channel filler %p", inChannel);
   pthread_mutex_lock(&asyncSoundMutex);
   sgAsyncSounds.qremove(inChannel);
   pthread_mutex_unlock(&asyncSoundMutex);
}

void asyncSoundSuspend()
{
   asyncSoundSuspended = true;
}


void asyncSoundResume()
{
   pthread_mutex_lock(&asyncSoundMutex);
   asyncSoundSuspended = false;
   asyncSoundPingLocked();
   pthread_mutex_unlock(&asyncSoundMutex);
}




// --- OpenALChannel ---------------------------------------------------
  

class OpenALChannel : public SoundChannel
{
public:
   Object *mSound;
   ALuint mSourceID;
   short  *mSampleBuffer;
   bool   mDynamicDone;
   ALuint mDynamicStackSize;
   ALuint mDynamicStack[2];
   ALuint mDynamicBuffer[2];
   AudioStream *mStream;
   int mLength;
   int mSize;
   int mStartTime;
   int mLoops;
   bool mUseStream;
   bool mStreamFinished;
   enum { STEREO_SAMPLES = 2 };
   bool mWasPlaying;
   bool mSuspended;
   

   OpenALChannel(Object *inSound, ALuint inBufferID, int startTime, int inLoops, const SoundTransform &inTransform)
   {
      init();
      //LOG_SOUND("OpenALChannel constructor %d",inBufferID);
      mSound = inSound;
      inSound->IncRef();

     
      float seek = 0;
      mStartTime = startTime;
      mLoops = inLoops;
      
      if (inBufferID>0)
      {
         // grab a source ID from openAL
         alGenSources(1, &mSourceID);
         
         alSourcei(mSourceID, AL_BUFFER, inBufferID);
         
         // set some basic source prefs
         alSourcef(mSourceID, AL_PITCH, 1.0f);
         alSourcef(mSourceID, AL_GAIN, inTransform.volume);
         alSource3f(mSourceID, AL_POSITION, (float) cos((inTransform.pan - 1) * (1.5707)), 0, (float) sin((inTransform.pan + 1) * (1.5707)));

         // TODO: not right!
         //if (inLoops>1)
            //alSourcei(mSourceID, AL_LOOPING, AL_TRUE);
         
         if (startTime > 0)
         {
            ALint bits, channels, freq;
            alGetBufferi(inBufferID, AL_SIZE, &mSize);
            alGetBufferi(inBufferID, AL_BITS, &bits);
            alGetBufferi(inBufferID, AL_CHANNELS, &channels);
            alGetBufferi(inBufferID, AL_FREQUENCY, &freq);
            mLength = (ALfloat)((ALuint)mSize/channels/(bits/8)) / (ALfloat)freq;
            seek = (startTime * 0.001) / mLength;
         }
         
         if (seek < 1)
         {
            //alSourceQueueBuffers(mSourceID, 1, &inBufferID);
            alSourcePlay(mSourceID);
            if (seek != 0)
            {
               alSourcef(mSourceID, AL_BYTE_OFFSET, seek * mSize);
            }
         }
         
         mWasPlaying = true;
         sgOpenChannels.push_back((intptr_t)this);
      }
   }
   
   
   OpenALChannel(Object *inSound, AudioStream *inStream, int startTime, int inLoops, const SoundTransform &inTransform)
   {
      init();
      mSound = inSound;
      inSound->IncRef();

      float seek = 0;
      int size = 0;
      
      mStartTime = startTime;
      mLoops = inLoops;
      
      mStream = inStream;
      mUseStream = true;
      mStreamFinished = false;
      
      if (mStream)
      {
         alGenBuffers(2, mDynamicBuffer);
         check("alGenBuffers");
         alGenSources(1, &mSourceID);
         check("alGenSources");

         alSource3f(mSourceID, AL_POSITION,        0.0, 0.0, 0.0);
         alSource3f(mSourceID, AL_VELOCITY,        0.0, 0.0, 0.0);
         alSource3f(mSourceID, AL_DIRECTION,       0.0, 0.0, 0.0);
         alSourcef (mSourceID, AL_ROLLOFF_FACTOR,  0.0          );
         alSourcei (mSourceID, AL_SOURCE_RELATIVE, AL_TRUE      );

         setTransform(inTransform);
         check("setTransform");
        
         primeStream();

         mWasPlaying = true;

         asyncSoundAdd(this);
      }
      else
      {
         mStreamFinished = true;
      }
      
      sgOpenChannels.push_back((intptr_t)this);
   }

   
   OpenALChannel(const ByteArray &inBytes,const SoundTransform &inTransform)
   {
      //LOG_SOUND("OpenALChannel dynamic %d",inBytes.Size());
      init();
     
      alGenBuffers(2, mDynamicBuffer);
      if (!mDynamicBuffer[0])
      {
         //LOG_SOUND("Error creating dynamic sound buffer!");
      }
      else
      {
         mSampleBuffer = new short[8192*STEREO_SAMPLES];
         
         // grab a source ID from openAL
         alGenSources(1, &mSourceID); 
         
         QueueBuffer(mDynamicBuffer[0],inBytes);
         
         if (!mDynamicDone)
            mDynamicStack[mDynamicStackSize++] = mDynamicBuffer[1];
         
         // set some basic source prefs
         alSourcef(mSourceID, AL_PITCH, 1.0f);
         alSourcef(mSourceID, AL_GAIN, inTransform.volume);
         alSource3f(mSourceID, AL_POSITION, (float) cos((inTransform.pan - 1) * (1.5707)), 0, (float) sin((inTransform.pan + 1) * (1.5707)));
         
         alSourcePlay(mSourceID);
      }
      
      //sgOpenChannels.push_back((intptr_t)this);
   }

   void init()
   {
      mSize = 0;
      mSound = 0;
      mSourceID = 0;
      mUseStream = false;

      mStream = 0;
      mUseStream = false;
      mStreamFinished = false;
      
      mDynamicDone = true;
      mDynamicBuffer[0] = 0;
      mDynamicBuffer[1] = 0;
      mDynamicStackSize = 0;
      mWasPlaying = true;
      mStream = 0;

      mStartTime = 0;
      mLoops = 0;
      mSuspended = false;
      mSampleBuffer = 0;
   }
 


   // Returns if the stream still has data.
   bool streamBuffer( ALuint inBuffer )
   {
      if (openal_is_shutdown)
         return false;
       
      if (mSuspended)
         return true;

      //LOG_SOUND("STREAM\n");
      char pcm[MAX_STREAM_BUFFER_SIZE];
      int bytes = ( (mStream->isStereo() ? 4 : 2) * mStream->getRate() * 400/1000 );
      if (bytes > MAX_STREAM_BUFFER_SIZE)
         bytes = MAX_STREAM_BUFFER_SIZE;
      bytes = bytes & ~7;
      int size = 0;
      bool justRewound = false;

      // Bytes per 400ms...


     // mSuspended->getRate

      while(size<bytes)
      {
          int filled = mStream->fillBuffer(pcm+size, bytes-size);
           
          if (filled <= 0)
          {
             if (justRewound)
             {
                size = 0;
                mLoops = 0;
                break;
             }

             if ( mLoops > 0 )
             {
                mLoops --;
                LOG_SOUND(" loops->%d\n", mLoops);
                mStream->rewind();
                justRewound = true;
             }
             else
             {
                if (size==0)
                   LOG_SOUND(" fill empty\n")
                else
                   LOG_SOUND(" fill done\n")
                break;
             }
          }
          else
          {
             justRewound = false;
             size += filled;
          }
      }

      if (size==0)
      {
         return false;
      }
      else
      {
         alBufferData(inBuffer, mStream->isStereo() ? AL_FORMAT_STEREO16 : AL_FORMAT_MONO16 , pcm, size,  mStream->getRate());

         alSourceQueueBuffers(mSourceID, 1, &inBuffer );
      }

      return true;
   }

   void primeStream()
   {
      if (openal_is_shutdown || mSuspended || !mStream->isValid())
         return;
  
      bool ok = streamBuffer(mDynamicBuffer[0]);
      if (ok)
      {
         streamBuffer(mDynamicBuffer[1]);
         if (!playing())
            alSourcePlay(mSourceID);
      }
      int queued = 0;
      alGetSourcei(mSourceID, AL_BUFFERS_QUEUED, &queued);

      check("primeStream");
      LOG_SOUND("Primed %d buffers\n", queued);
   }


   void updateStream()
   {
      if (openal_is_shutdown || mStreamFinished || mSuspended || !mStream || !mStream->isValid())
      {
         LOG_SOUND("Dead stream.\n");
         return;
      }
      
      bool added = false;
      int processed = 0;
      alGetSourcei(mSourceID, AL_BUFFERS_PROCESSED, &processed);
      check("alGetSourcei processed");

      while(processed--)
      {
         ALuint buffer = 0;
         alSourceUnqueueBuffers(mSourceID, 1, &buffer);
         check("alSourceUnqueueBuffers");
           
         if (buffer && streamBuffer(buffer))
           added = true;
         else
            LOG_SOUND("  Could not stream processed buffer %d.\n", buffer);
      }

      int queued = 0;
      alGetSourcei(mSourceID, AL_BUFFERS_QUEUED, &queued);
      check("alGetSourcei queued");
      if (queued==0)
      {
         LOG_SOUND("All buffers gone, stop.");
         mStreamFinished = true;
      }
      else
      {
         if (queued<2)
            LOG_SOUND(" -> only queued %d.", queued);
         if (added)
            kickstart();
      }
   }

   void asyncUpdate()
   {
      updateStream();
   }


   bool playing()
   {
      if (openal_is_shutdown) return false;
       
      ALint state;
      alGetSourcei(mSourceID, AL_SOURCE_STATE, &state);
      check("playing");
      return (state == AL_PLAYING);

   }



   void check(const char *where)
   {
      if (openal_is_shutdown) return;
      int error = alGetError();
      if(error != AL_NO_ERROR)
      {
         //todo : print meaningful errors instead
         LOG_SOUND(">>>>> OpenAL error was raised: %d in %s\n", error, where);
      }
   }

  
   
   void QueueBuffer(ALuint inBuffer, const ByteArray &inBytes)
   {
      int time_samples = inBytes.Size()/sizeof(float)/STEREO_SAMPLES;
      const float *buffer = (const float *)inBytes.Bytes();
      
      for(int i=0;i<time_samples;i++)
      {
         mSampleBuffer[ i<<1 ] = *buffer++ * ((1<<15)-1);
         mSampleBuffer[ (i<<1) + 1 ] = *buffer++ * ((1<<15)-1);
      }
      
      mDynamicDone = time_samples < 1024;
      
      alBufferData(inBuffer, AL_FORMAT_STEREO16, mSampleBuffer, time_samples*STEREO_SAMPLES*sizeof(short), 44100 );
      
      //LOG_SOUND("Dynamic queue buffer %d (%d)", inBuffer, time_samples );
      alSourceQueueBuffers(mSourceID, 1, &inBuffer );
   }
   
   
   void unqueueBuffers()
   {
      ALint processed = 0;
      alGetSourcei(mSourceID, AL_BUFFERS_PROCESSED, &processed);
      //LOG_SOUND("Recover buffers : %d (%d)", processed, mDynamicStackSize);
      if (processed)
      {
         alSourceUnqueueBuffers(mSourceID,processed,&mDynamicStack[mDynamicStackSize]);
         mDynamicStackSize += processed;
      }
   }
   
   
   bool needsData()
   {
      if (mUseStream || !mDynamicBuffer[0] || mDynamicDone)
         return false;
      
      unqueueBuffers();
      
      //LOG_SOUND("needsData (%d)", mDynamicStackSize);
      if (mDynamicStackSize)
      {
         mDynamicDone = true;
         return true;
      }
      
      return false;
      
   }

   void kickstart()
   {
      ALint val = 0;
      alGetSourcei(mSourceID, AL_SOURCE_STATE, &val);
      if (val != AL_PLAYING)
      {
         LOG_SOUND("Kickstart after stall\n");
         // This is an indication that the previous buffer finished playing before we could deliver the new buffer.
         // You will hear ugly popping noises...
         alSourcePlay(mSourceID);
         check("Kickstart");
      }
   }
   
   
   void addData(const ByteArray &inBytes)
   {
      if (!mDynamicStackSize)
      {
         //LOG_SOUND("Adding data with no buffers?");
         return;
      }
      mDynamicDone = false;
      ALuint buffer = mDynamicStack[0];
      mDynamicStack[0] = mDynamicStack[1];
      mDynamicStackSize--;
      QueueBuffer(buffer,inBytes);
      
      // Make sure it is still playing ...
      if (!mDynamicDone && mDynamicStackSize==1)
         kickstart();
   }
   
   
   ~OpenALChannel()
   {
      if (mStream)
         asyncSoundRemove(this);

      if (!openal_is_shutdown)
      {
         check("Pre ~OpenALChannel");
         if (mSourceID)
         {
            ALint state;
            alGetSourcei(mSourceID, AL_SOURCE_STATE, &state);
            if (state == AL_PLAYING)
            {
               alSourceStop(mSourceID);
               check("~OpenALChannel stop");
            }

            int queued;
            alGetSourcei(mSourceID, AL_BUFFERS_QUEUED, &queued);
            check("~OpenALChannel queued");
    
            while(queued--)
            {
               ALuint buffer;
               alSourceUnqueueBuffers(mSourceID, 1, &buffer);
               check("~OpenALChannel alSourceUnqueueBuffers");
            }

            //LOG_SOUND("OpenALChannel destructor");
            alDeleteSources(1, &mSourceID);
            check("~OpenALChannel alDeleteSources");
          }

          if (mDynamicBuffer[0])
          {
             alDeleteBuffers(2, mDynamicBuffer);
             check("~OpenALChannel alDeleteBuffers");
          }
      }

      delete [] mSampleBuffer;

      if (mSound)
         mSound->DecRef();

      delete mStream;
      
      for (int i = 0; i < sgOpenChannels.size(); i++)
      {
         if (sgOpenChannels[i] == (intptr_t)this)
         {
            sgOpenChannels.erase(i, 1);
            break;
         }
      }
   }
   
   
   bool isComplete()
   {
      if (mUseStream)
      {
         //updateStream();
         if (mStreamFinished)
            LOG_SOUND("mStreamFinished!\n");
         return mStreamFinished;
      }
      
      if (!mSourceID)
      {
         //LOG_SOUND("OpenALChannel isComplete() - never started!");
         return true;
      }
      
      if (!mDynamicDone)
         return false;
      
      // got this hint from
      // http://www.gamedev.net/topic/410696-openal-how-to-query-if-a-source-sound-is-playing-solved/
      ALint state;
      alGetSourcei(mSourceID, AL_SOURCE_STATE, &state);
      check("isComplete");
      /*
       Possible values of state
       AL_INITIAL
       AL_STOPPED
       AL_PLAYING
       AL_PAUSED
       */
      if(state == AL_STOPPED)
      {
         if (mLoops > 0)
         {   
            float seek = 0;
            
            if (mStartTime > 0)
            {
               seek = (mStartTime * 0.001) / mLength;
            }
            
            if (seek < 1)
            {
               //alSourceQueueBuffers(mSourceID, 1, &inBufferID);
               alSourcePlay(mSourceID);
               alSourcef(mSourceID, AL_BYTE_OFFSET, seek * mSize);
            }
            
            mLoops --;
            
            return false;
         }
         else
         {
            return true;
         }
         //LOG_SOUND("OpenALChannel isComplete() returning true");
      }
      else
      {
         //LOG_SOUND("OpenALChannel isComplete() returning false");
         return false;
      }
   }
   
   
   double getLeft()  
   {
      if (mSourceID)
      {
         float panX=0;
         float panY=0;
         float panZ=0;
         alGetSource3f(mSourceID, AL_POSITION, &panX, &panY, &panZ);
         check("getLeft");
         return (1-panX)/2;
      }
      return 0.5;
   }
   
   
   double getRight()   
   {
      if (mSourceID)
      {
         float panX=0;
         float panY=0;
         float panZ=0;
         alGetSource3f(mSourceID, AL_POSITION, &panX, &panY, &panZ);
         check("getRight");
         return (panX+1)/2;
      }
      return 0.5;
   }
   
   
   double setPosition(const float &inFloat)
   {
      if (mUseStream)
      {
         return mStream ? mStream->setPosition(inFloat) : inFloat;
      }
      else
      {
         alSourcef(mSourceID,AL_SEC_OFFSET,inFloat);
         return inFloat;
      }
   }
   
   
   double getPosition() 
   {
      if (mUseStream)
      {
         return mStream ? mStream->getPosition() : 0;
      }
      else
      {
         float pos = 0;
         alGetSourcef(mSourceID, AL_SEC_OFFSET, &pos);
         return pos * 1000.0;
      }
   }
   
   
   void setTransform(const SoundTransform &inTransform)
   {
      alSourcef(mSourceID, AL_GAIN, inTransform.volume);
      alSource3f(mSourceID, AL_POSITION, (float) cos((inTransform.pan - 1) * (1.5707)), 0, (float) sin((inTransform.pan + 1) * (1.5707)));
      check("setTransform");
   }
   
   
   void stop()
   {
      if (mUseStream)
      {
         if (mStream)
         {
            asyncSoundRemove(this);
            delete mStream;
            mStream = 0;
            mStreamFinished = true;
            mWasPlaying = false;
         }
      }
      else
      {
         ALint state;
         alGetSourcei(mSourceID, AL_SOURCE_STATE, &state);
         
         if (state == AL_PLAYING)
         {
            alSourceStop(mSourceID);
         }
         check("stop");
      }
   }
   
   
   void suspend()
   {
      ALint state;
      alGetSourcei(mSourceID, AL_SOURCE_STATE, &state);
        
      if (state == AL_PLAYING)
      {
         alSourcePause(mSourceID);
         check("pause for suspend");
         mWasPlaying = true;
         return;
      }
         
      mWasPlaying = false;
   }
   
   
   void resume()
   {
      if (mWasPlaying)
      {
         alSourcePlay(mSourceID);
         check("resume");
      }
   }
   
};

// ---   OpenALSound ----------------------------


class OpenALSound : public Sound
{
public:
   ALint bufferSize;
   ALint frequency;
   ALint bitsPerSample;
   ALint channels;

   ALuint mBufferID;
   double mTotalTime;
   bool mIsStream;
   std::string mStreamPath;
   std::string mError;
         
   OpenALSound(const std::string &inFilename, bool inForceMusic)
   {
      IncRef();
      mBufferID = 0;
      mIsStream = false;
      mTotalTime = -1;
      
      #ifdef HX_MACOS
      char fileURL[1024];
      GetBundleFilename(inFilename.c_str(),fileURL,1024);
      #else
      #ifdef IPHONE
      std::string asset = inFilename[0]=='/' ? inFilename : GetResourcePath() + gAssetBase + inFilename;
      const char *fileURL = asset.c_str();
      #else
      const char *fileURL = inFilename.c_str();
      #endif
      #endif
      
      if (!fileURL) {
         
         //LOG_SOUND("OpenALSound constructor() error in url");
         mError = "Error int url: " + inFilename;

      } else {

         QuickVec<uint8> buffer;
         int _channels;
         int _bitsPerSample;
         ALenum  format;
         ALsizei freq;
         bool ok = false; 


         int error = alGetError();
         if(error != AL_NO_ERROR)
            LOG_SOUND("Clearing openal error : %d\n", error);

            //Determine the file format before we try anything
         AudioFormat type = Audio::determineFormatFromFile(std::string(fileURL));
         switch(type) {
            case eAF_ogg:
               if (inForceMusic)
               {
                  mIsStream = true;
                  mStreamPath = fileURL;
               }
               else
               {
                  ok = Audio::loadOggSampleFromFile( fileURL, buffer, &_channels, &_bitsPerSample, &freq );
                  if (!ok)
                     LOG_SOUND("Error in Audio::loadOggSampleFromFile %s\n", fileURL);
               }
            break;
            case eAF_wav:
               ok = Audio::loadWavSampleFromFile( fileURL, buffer, &_channels, &_bitsPerSample, &freq );
               if (!ok)
                  LOG_SOUND("Error loading wav %s\n", fileURL);
            break;
            default:
               LOG_SOUND("Error opening sound file, unsupported type.\n");
         }
         
         if (mIsStream)
            return;
         
            //Work out the format from the data
         if (_channels == 1) {
            if (_bitsPerSample == 8 ) {
               format = AL_FORMAT_MONO8;
            } else if (_bitsPerSample == 16) {
               format = (int)AL_FORMAT_MONO16;
            }
         } else if (_channels == 2) {
            if (_bitsPerSample == 8 ) {
               format = (int)AL_FORMAT_STEREO8;
            } else if (_bitsPerSample == 16) {
               format = (int)AL_FORMAT_STEREO16;
            }
         } //channels = 2
          
         
         if (!ok)
         {
            LOG_SOUND("Error opening sound data\n");
            mError = "Error opening sound data";
         }
         else if (alGetError() != AL_NO_ERROR)
         {
            LOG_SOUND("Error after opening sound data\n");
            mError = "Error after opening sound data";  
         }
         else
         {
               // grab a buffer ID from openAL
            alGenBuffers(1, &mBufferID);
            
               // load the awaiting data blob into the openAL buffer.
            alBufferData(mBufferID,format,&buffer[0],buffer.size(),freq); 

               // once we have all our information loaded, get some extra flags
            alGetBufferi(mBufferID, AL_SIZE, &bufferSize);
            alGetBufferi(mBufferID, AL_FREQUENCY, &frequency);
            alGetBufferi(mBufferID, AL_CHANNELS, &channels);    
            alGetBufferi(mBufferID, AL_BITS, &bitsPerSample); 
            
         } //!ok
      }
   }
   
   
   OpenALSound(float *inData, int len)
   {
      IncRef();
      mBufferID = 0;
      mIsStream = false;
      
      QuickVec<uint8> buffer;
      int _channels;
      int _bitsPerSample;
      ALenum  format;
      ALsizei freq;
      bool ok = false; 
      
      check("Pre OpenALSound");
      //Determine the file format before we try anything
      AudioFormat type = Audio::determineFormatFromBytes(inData, len);
      
      switch(type) {
         case eAF_ogg:
            ok = Audio::loadOggSampleFromBytes(inData, len, buffer, &_channels, &_bitsPerSample, &freq );
         break;
         case eAF_wav:
            ok = Audio::loadWavSampleFromBytes(inData, len, buffer, &_channels, &_bitsPerSample, &freq );
         break;
         default:
            LOG_SOUND("Error opening sound file, unsupported type.\n");
      }
      
      //Work out the format from the data
      if (_channels == 1) {
         if (_bitsPerSample == 8 ) {
            format = AL_FORMAT_MONO8;
         } else if (_bitsPerSample == 16) {
            format = (int)AL_FORMAT_MONO16;
         }
      } else if (_channels == 2) {
         if (_bitsPerSample == 8 ) {
            format = (int)AL_FORMAT_STEREO8;
         } else if (_bitsPerSample == 16) {
            format = (int)AL_FORMAT_STEREO16;
         }
      } //channels = 2
       
      
      if (!ok)
      {
         LOG_SOUND("Error opening sound data\n");
         mError = "Error opening sound data";
      }
      else
      {
            // grab a buffer ID from openAL
         alGenBuffers(1, &mBufferID);
         
            // load the awaiting data blob into the openAL buffer.
         alBufferData(mBufferID,format,&buffer[0],buffer.size(),freq); 
         check("OpenALSound alBufferData");

            // once we have all our information loaded, get some extra flags
         alGetBufferi(mBufferID, AL_SIZE, &bufferSize);
         alGetBufferi(mBufferID, AL_FREQUENCY, &frequency);
         alGetBufferi(mBufferID, AL_CHANNELS, &channels);    
         alGetBufferi(mBufferID, AL_BITS, &bitsPerSample); 
         
      }
      check("Post OpenALSound");
   }
   
   void check(const char *where)
   {
      if (openal_is_shutdown) return;
      int error = alGetError();
      if(error != AL_NO_ERROR)
      {
         LOG_SOUND(">>>>> OpenAL error was raised: %d in %d\n", error, where);
      }
   }


   
   ~OpenALSound()
   {
      //LOG_SOUND("OpenALSound destructor() ###################################");
      if (mBufferID!=0)
         alDeleteBuffers(1, &mBufferID);
   }
   
   
   double getLength()
   {
      if (mTotalTime == -1)
      {
         if (mIsStream)
         {
            AudioStream *audioStream = AudioStream::createOgg();
            if (audioStream)
            {
               int length = audioStream->getLength(mStreamPath.c_str());
               mTotalTime = length * 1000;
               delete audioStream;
            }
            else
            {
               mTotalTime = 0;
            }
         }
         else
         {
            double result = ((double)bufferSize) / (frequency * channels * (bitsPerSample/8) );
            
            //LOG_SOUND("OpenALSound getLength returning %f", toBeReturned);
            mTotalTime = result * 1000;
         }
      }
      return mTotalTime;
   }
   
   
   void getID3Value(const std::string &inKey, std::string &outValue)
   {
      //LOG_SOUND("OpenALSound getID3Value returning empty string");
      outValue = "";
   }
   
   
   int getBytesLoaded()
   {
      int toBeReturned = ok() ? 100 : 0;
      //LOG_SOUND("OpenALSound getBytesLoaded returning %i", toBeReturned);
      return toBeReturned;
   }
   
   
   int getBytesTotal()
   {
      int toBeReturned = ok() ? 100 : 0;
      //LOG_SOUND("OpenALSound getBytesTotal returning %i", toBeReturned);
      return toBeReturned;
   }
   
   
   bool ok()
   {
      bool toBeReturned = mError.empty();
      //LOG_SOUND("OpenALSound ok() returning BOOL = %@\n", (toBeReturned ? @"YES" : @"NO")); 
      return toBeReturned;
   }
   
   
   std::string getError()
   {
      //LOG_SOUND("OpenALSound getError()"); 
      return mError;
   }
   
   
   void close()
   {
      //LOG_SOUND("OpenALSound close() doing nothing"); 
   }
   
   
   SoundChannel *openChannel(double startTime, int loops, const SoundTransform &inTransform)
   {
      //LOG_SOUND("OpenALSound openChannel()"); 
      if (mIsStream)
      {
         AudioStream *audioStream = AudioStream::createOgg();
         if (!audioStream->open(mStreamPath.c_str(), startTime))
         {
            delete audioStream;
            audioStream = 0;
         }
         
         return new OpenALChannel(this, audioStream, startTime, loops, inTransform);
      }
      else
      {
         return new OpenALChannel(this, mBufferID, startTime, loops, inTransform);
      }
   }
 
}; // end OpenALSound
   


// --- External Sound implementation -------------------
   

SoundChannel *SoundChannel::Create(const ByteArray &inBytes,const SoundTransform &inTransform)
{
   if (!OpenALInit())
      return 0;
   
   return new OpenALChannel(inBytes, inTransform);
}

  

#ifndef IPHONE
Sound *Sound::Create(const std::string &inFilename,bool inForceMusic)
{
   //Always check if openal is intitialized
   if (!OpenALInit())
      return 0;
   
   //Return a reference
   OpenALSound *sound;
   
   #ifdef ANDROID
   if (!inForceMusic)
   {
      ByteArray bytes = AndroidGetAssetBytes(inFilename.c_str());
      sound = new OpenALSound((float*)bytes.Bytes(), bytes.Size());
   }
   else
   {
      sound = new OpenALSound(inFilename, inForceMusic);
   }
   #else
   sound = new OpenALSound(inFilename, inForceMusic);
   #endif
   
   if (sound->ok ())
      return sound;
   else
      return 0;
}


Sound *Sound::Create(float *inData, int len, bool inForceMusic)
{
   //Always check if openal is intitialized
   if (!OpenALInit())
      return 0;

   //Return a reference
   OpenALSound *sound = new OpenALSound(inData, len);
   
   if (sound->ok ())
      return sound;
   else
      return 0;
}
#endif


void Sound::Suspend()
{
   //Always check if openal is initialized
   if (!OpenALInit())
      return;
   
   asyncSoundSuspend();

   OpenALChannel* channel = 0;
   for (int i = 0; i < sgOpenChannels.size(); i++)
   {
      channel = (OpenALChannel*)(sgOpenChannels[i]);
      if (channel)
      {
         channel->suspend();
      }
   }
   
   alcMakeContextCurrent(0);
   alcSuspendContext(sgContext);
   
   #ifdef ANDROID
   alcSuspend();
   #endif
}


void Sound::Resume()
{
   //Always check if openal is initialized
   if (!OpenALInit())
      return;
   
   #ifdef ANDROID
   alcResume();
   #endif
   
   alcMakeContextCurrent(sgContext);
   
   OpenALChannel* channel = 0;
   for (int i = 0; i < sgOpenChannels.size(); i++)
   {
      channel = (OpenALChannel*)(sgOpenChannels[i]);
      if (channel)
      {
         channel->resume();
      }
   }

   asyncSoundResume();
   
   alcProcessContext(sgContext);
}


void Sound::Shutdown()
{
   OpenALClose();
}

     
Sound *Sound::CreateOpenAl(const std::string &inFilename, bool inForceMusic)
{
   if (!OpenALInit())
      return 0;
   return new OpenALSound(inFilename, inForceMusic);
}

Sound *Sound::CreateOpenAl(float *inData, int len)
{
   if (!OpenALInit())
      return 0;
   return new OpenALSound(inData, len);
}



} // end namespace nme
