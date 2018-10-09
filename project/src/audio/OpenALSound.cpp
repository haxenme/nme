#ifdef EMSCRIPTEN
#include <AL/al.h>
#include <AL/alc.h>
#else
#include <OpenAL/al.h>
#include <OpenAL/alc.h>
#endif

#include <math.h>
#include <Sound.h>
#include <nme/QuickVec.h>
#include <Utils.h>
#include "Audio.h"
#include <NMEThread.h>
#include <unistd.h>
#include <sys/time.h>

typedef unsigned char uint8;


#define MAX_STREAM_BUFFER_SIZE (45000 * 4 * 400/1000)


namespace nme
{

// --- OpenAl implementation -----------------------

static ALCdevice  *sgDevice = 0;
static ALCcontext *sgContext = 0;


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
   }
   return sgContext;
}

bool OpenALClose()
{
   if (openal_is_init && !openal_is_shutdown)
   {
      openal_is_shutdown = true;
      clShutdown();
      alcMakeContextCurrent(0);
      if (sgContext) alcDestroyContext(sgContext);
      if (sgDevice) alcCloseDevice(sgDevice);
   }
   return true;
}





// --- OpenALChannel ---------------------------------------------------
  


class OpenALSourceChannel : public SoundChannel
{
public:
   Object *soundObject;
   ALuint sourceId;
   bool   suspended;
   bool   playOnResume;
   double duration;
   double t0;

   OpenALSourceChannel(Object *inSound, const SoundTransform &inTransform)
   {
      soundObject = inSound;
      if (soundObject)
         soundObject->IncRef();
      sourceId = 0;
      duration = 0.0;
      t0 = 0.0;
      suspended = false;
      playOnResume = false;

      alGenSources(1, &sourceId);
      check("genSource");

      alSourcef(sourceId, AL_PITCH, 1.0f);
      alSource3f(sourceId, AL_POSITION,        0.0, 0.0, 0.0);
      alSource3f(sourceId, AL_VELOCITY,        0.0, 0.0, 0.0);
      alSource3f(sourceId, AL_DIRECTION,       0.0, 0.0, 0.0);
      alSourcef(sourceId, AL_ROLLOFF_FACTOR,  0.0          );
      alSourcei(sourceId, AL_SOURCE_RELATIVE, AL_TRUE      );
      check("setSource");
   
      setTransform(inTransform);
   }

   ~OpenALSourceChannel()
   {
      stop();
   }

   
   void setTransform(const SoundTransform &inTransform)
   {
      alSourcef(sourceId, AL_GAIN, inTransform.volume);
      alSource3f(sourceId, AL_POSITION, (float) cos((inTransform.pan - 1) * (1.5707)), 0, (float) sin((inTransform.pan + 1) * (1.5707)));
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



   bool playing()
   {
      if (openal_is_shutdown)
         return false;
       
      ALint state;
      alGetSourcei(sourceId, AL_SOURCE_STATE, &state);
      check("playing");
      return (state == AL_PLAYING);
   }

   void stop()
   {
      clRemoveChannel(this);

      if (!openal_is_shutdown && sourceId)
      {
         if (playing()) 
         {
            alSourceStop(sourceId);
            check("stop");
         }
         alSourcei(sourceId, AL_BUFFER, 0);
         alDeleteSources(1, &sourceId);
      }
      sourceId = 0;
   
      if (soundObject)
      {
         soundObject->DecRef();
         soundObject = 0;
      }
   }
   
   
   void suspend()
   {
      playOnResume = !isComplete();
      suspended = true;
      if (playing())
      {
         alSourcePause(sourceId);
         check("pause for suspend");
         return;
      }
   }
   
   
   void resume()
   {
      if (playOnResume)
      {
         alSourcePlay(sourceId);
         check("resume");
         suspended = false;
         playOnResume = false;
      }
   }
  
   
   double getLeft()  
   {
      #ifndef EMSCRIPTEN
      if (sourceId)
      {
         float panX=0;
         float panY=0;
         float panZ=0;
         alGetSource3f(sourceId, AL_POSITION, &panX, &panY, &panZ);
         check("getLeft");
         return (1-panX)/2;
      }
      #endif
      return 0.5;
   }
   
   
   double getRight()   
   {
      #ifndef EMSCRIPTEN
      if (sourceId)
      {
         float panX=0;
         float panY=0;
         float panZ=0;
         alGetSource3f(sourceId, AL_POSITION, &panX, &panY, &panZ);
         check("getRight");
         return (panX+1)/2;
      }
      #endif
      return 0.5;
   }
 

   
   double getLength() { return duration*1000.0; }

   double setPosition(const float &inFloat)
   {
      alSourcef(sourceId,AL_SEC_OFFSET,inFloat);
      return inFloat;
   }
   
   
   double getPosition() 
   {
      ALfloat pos = 0;
      alGetSourcef(sourceId, AL_SEC_OFFSET, &pos);
      return (t0+pos) * 1000.0;
   }
 

};





class OpenALBufferChannel : public OpenALSourceChannel
{
public:
   ALuint bufferId;
   ALint  byteSize;
   int    loops;
   bool   hasBufferedData;
   bool   isAsync;

   OpenALBufferChannel(Object *inSound, const SoundTransform &inTransform, ALuint inBufferId, int startTime, int inLoops)
      : OpenALSourceChannel(inSound, inTransform )
   {
      int seekBytes=0;

      bufferId = inBufferId;
      alSourcei(sourceId, AL_BUFFER, bufferId);
      loops = inLoops>0 ? inLoops -1 : inLoops;

      byteSize = 0;
      ALint bits=8;
      ALint channels=1;
      ALint freq=44100;

      alGetBufferi(bufferId, AL_SIZE, &byteSize);
      alGetBufferi(bufferId, AL_BITS, &bits);
      alGetBufferi(bufferId, AL_CHANNELS, &channels);
      alGetBufferi(bufferId, AL_FREQUENCY, &freq);
      duration = (double)byteSize*8/(channels*bits*freq);

      bool tooMuchSeek = false;
      if (duration && inSound)
      {
         seekBytes = ( (startTime*0.001)*byteSize/ duration );
         int seekLoops = seekBytes/byteSize;
         seekBytes -= seekLoops*byteSize;
         if (loops>=0)
         {
            loops -= seekLoops;
            if (loops<0)
               tooMuchSeek = true;
         }
     
         seekBytes & ~0x3; // 2 channels, 16 bit round
      }
     
      
      hasBufferedData = false;
      isAsync = false;
      if (!tooMuchSeek)
      {
         hasBufferedData = true;
         alSourcePlay(sourceId);
         if (seekBytes && seekBytes<byteSize)
            alSourcef(sourceId, AL_BYTE_OFFSET, seekBytes);
         clAddChannel(this, isAsync = loops!=0);
      }
   }


   ~OpenALBufferChannel()
   {
      stop();
   }

   void stop()
   {
      OpenALSourceChannel::stop();
      loops = 0;
      hasBufferedData = false;
   }

   void asyncUpdate()
   {
      if (!playing())
      {
         if (loops!=0)
         {
            alSourcef(sourceId, AL_BYTE_OFFSET, 0);
            alSourcePlay(sourceId);
            if (loops>0)
               loops--;
         }
         else
            stop();
      }
   }

   bool isComplete()
   {
      // Sync channels will not get asyncUpdate calls, so check here
      if (!openal_is_shutdown && !isAsync && hasBufferedData && !playing() && !loops && !playOnResume)
      {
         stop();
      }
      return !openal_is_shutdown && !loops && !hasBufferedData;
   }

};







class OpenALDoubleBufferChannel : public OpenALSourceChannel
{
public:
   ALuint  bufferIds[2];
   int     playedBytes;

   NmeMutex bufferMutex;
   ALuint   freeBuffers[2];
   int      freeBufferCount;
   bool     isStopped;

   OpenALDoubleBufferChannel(Object *inSound, const SoundTransform &inTransform)
      : OpenALSourceChannel(inSound, inTransform )
   {
      bufferIds[0] = bufferIds[1] = 0;
      freeBufferCount = 0;
      playedBytes = 0;
      isStopped = true;
  }

   void createBuffers()
   {
      alGenBuffers(2, bufferIds);
      freeBuffers[ freeBufferCount++ ] = bufferIds[0];
      freeBuffers[ freeBufferCount++ ] = bufferIds[1];
      isStopped = false;
      check("alGenBuffers");
   }


   void stop()
   {
      OpenALSourceChannel::stop();

      if (openal_is_shutdown)
         return;

      if (bufferIds[0])
         alDeleteBuffers(2, bufferIds);
      freeBufferCount = 0;
      isStopped = true;
   }
  
   void unqueueBuffers()
   {
      int processed = 0;
      alGetSourcei(sourceId, AL_BUFFERS_PROCESSED, &processed);
      while(processed--)
      {
         ALuint buffer = 0;
         alSourceUnqueueBuffers(sourceId, 1, &buffer);
         addBufferOffset(buffer);
         addFreeBuffer(buffer);
      }
   }
  

   void addBufferOffset(ALuint buffer)
   {
      ALint bytes = 0;
      ALint bits=8;
      ALint channels=1;
      ALint freq=44100;

      alGetBufferi(buffer, AL_SIZE, &bytes);
      alGetBufferi(buffer, AL_BITS, &bits);
      alGetBufferi(buffer, AL_CHANNELS, &channels);
      alGetBufferi(buffer, AL_FREQUENCY, &freq);
      t0 += (double)(bytes * 8) / (channels * freq * bits);
   }



   ALuint getFreeBuffer()
   {
      if (openal_is_shutdown || suspended)
         return 0;

      int processed = 0;
      alGetSourcei(sourceId, AL_BUFFERS_PROCESSED, &processed);
      if (processed>0)
      {
         ALuint result = 0;
         alSourceUnqueueBuffers(sourceId, 1, &result);
         addBufferOffset(result);
         check("alGetSourcei processed");
         return result;
      }

      NmeAutoMutex lock(bufferMutex);
      if (freeBufferCount)
         return freeBuffers[--freeBufferCount];
      return 0;
   }


   void addFreeBuffer(ALuint inBufferId)
   {
      NmeAutoMutex lock(bufferMutex);
      if (freeBufferCount<2)
         freeBuffers[freeBufferCount++] = inBufferId;
      else
         LOG_SOUND("Bad freeBufferCount");
   }
   virtual bool isComplete() = 0;

};



class OpenALStreamChannel : public OpenALDoubleBufferChannel
{
public:
   INmeSoundStream *stream;
   int             loops;

   OpenALStreamChannel(Object *inSound, const SoundTransform &inTransform, INmeSoundStream *inStream)
      : OpenALDoubleBufferChannel(inSound, inTransform )
   {
      stream = inStream;
   }


   void stop()
   {
      OpenALDoubleBufferChannel::stop();
      if (stream)
      {
         delete stream;
         stream = 0;
      }
   }


   // Returns if the stream still has data.
   bool streamBuffer( ALuint inBuffer )
   {
      if (!stream)
      {
         return false;
      }

      //LOG_SOUND("STREAM\n");
      char pcm[MAX_STREAM_BUFFER_SIZE];
      int bytes = ( (stream->getIsStereo() ? 4 : 2) * stream->getRate() * 400/1000 );
      if (bytes > MAX_STREAM_BUFFER_SIZE)
         bytes = MAX_STREAM_BUFFER_SIZE;
      bytes = bytes & ~7;
      int size = 0;
      int emptyBuffersCount = 0;

      // Bytes per 400ms...

      while(size<bytes)
      {
          int filled = stream->fillBuffer(pcm+size, bytes-size);
           
          if (filled <= 0)
          {
             if (!tryAgainOnEmptyBuffer(emptyBuffersCount++))
                break;
          }
          else
          {
             emptyBuffersCount = 0;
             size += filled;
          }
      }

      if (size==0)
      {
         addFreeBuffer(inBuffer);
         return false;
      }

      alBufferData(inBuffer, stream->getIsStereo() ? AL_FORMAT_STEREO16 : AL_FORMAT_MONO16 , pcm, size,  stream->getRate());

      alSourceQueueBuffers(sourceId, 1, &inBuffer );

      return true;
   }

   bool updateStream()
   {
      if (openal_is_shutdown || !stream || suspended)
      {
         LOG_SOUND("Dead stream.\n");
         return false;
      }

  
      bool added = false;
      while(true)
      {
         ALuint buffer = getFreeBuffer();
         if (!buffer)
            break;
         if (!streamBuffer(buffer))
            break;
         added = true;
      }

      if (added && !playing())
         alSourcePlay(sourceId);
            
      return added;
   }



   virtual bool tryAgainOnEmptyBuffer(int inEmptyBufferCount)
   {
      return true;
   }

   void asyncUpdate()
   {
      updateStream();
   }

};





class OpenALStaticStreamChannel : public OpenALStreamChannel
{
public:
   int  loops;

   OpenALStaticStreamChannel(Object *inSound, const SoundTransform &inTransform, INmeSoundStream *inStream, int startTime, int inLoops)
      : OpenALStreamChannel(inSound, inTransform, inStream )
   {
      loops = inLoops >0 ? inLoops-1 : inLoops;

      duration = stream->getDuration();
      bool tooMuchSeek = false;

      if (duration)
      {
         double skip = startTime * 0.001;
         int skipLoops = (skip/duration);
         skip -= skipLoops*duration;
         if (loops>0)
         {
            loops -= skipLoops;
            if (loops<0)
               tooMuchSeek = true;
         }
    
         if (!tooMuchSeek)
         {
            createBuffers();

            if (skip)
            {
               t0 = stream->setPosition(skip);
            }

            if (updateStream())
            {
               clAddChannel(this,true);
            }
         }
      }
   }

   bool isComplete()
   {
      return !openal_is_shutdown && (freeBufferCount==2 || isStopped);
   }



   virtual bool tryAgainOnEmptyBuffer(int inEmptyBufferCount)
   {
      if (inEmptyBufferCount>0)
      {
         // Two empty buffers in a row = error
         stop();
         return false;
      }

	   if ( loops )
	   {
		   if (loops>0)
			   loops--;
		   LOG_SOUND(" loops->%d\n", loops);
         t0 = 0;
		   stream->rewind();
		   return true;
	   }

		LOG_SOUND("end of static data.\n")
      return false;
   }


};






class OpenALSyncUpdateChannel : public OpenALDoubleBufferChannel
{
public:
   SoundDataFormat dataFormat;
   ALuint openAlFormat;
   std::vector<short> convertBuffer;
   bool syncDataPending;
   bool noMoreData;
   bool isStereo;
   int  rate;
   int  sampleSize;
   

   OpenALSyncUpdateChannel(const SoundTransform &inTransform,SoundDataFormat inFormat, bool inIsStereo, int inRate)
      : OpenALDoubleBufferChannel(0, inTransform )
   {
      syncDataPending = false;
      noMoreData = false;
      isStereo = inIsStereo;
      rate = inRate;
      createBuffers();
      dataFormat = inFormat;
      sampleSize = 0;
      openAlFormat = 0;
      switch(dataFormat)
      {
         case sdfByte:
            openAlFormat = isStereo ? AL_FORMAT_STEREO8 : AL_FORMAT_MONO8;
            sampleSize = isStereo ? 2 : 1;
            break;

         case sdfShort:
            openAlFormat = isStereo ? AL_FORMAT_STEREO16 : AL_FORMAT_MONO16;
            sampleSize = isStereo ? 4 : 2;
            break;

         case sdfFloat:
            openAlFormat = isStereo ? AL_FORMAT_STEREO16 : AL_FORMAT_MONO16;
            sampleSize = isStereo ? 8 : 4;
            break;
      }
      
      clAddChannel(this, false);
   }


   bool needsData()
   {
      if (openal_is_shutdown || suspended || syncDataPending || noMoreData || isStopped)
         return false;

      unqueueBuffers();

      if (freeBufferCount==0)
         return false;

      return true;
   }

   bool isComplete()
   {
      if (openal_is_shutdown)
         return false;
      if (isStopped)
         return true;
      if (noMoreData)
      {
         if (freeBufferCount<2)
         {
            unqueueBuffers();
            if (freeBufferCount==2)
               stop();
         }
         return freeBufferCount==2;
      }
      return false;
   }


   
   void addData(const ByteArray &inBytes)
   {
      const unsigned char *data = inBytes.Bytes();
      int size = inBytes.Size();

      if (size>0)
      {
         ALuint buffer = getFreeBuffer();
         if (!buffer)
         {
            // Should not have 'needsData' ?
            LOG_SOUND("addData - no free buffer");
            return;
         }

         if (dataFormat==sdfFloat)
         {
            int values = size/sizeof(float);
            float *src = (float *)data;

            convertBuffer.resize(values);
            short *dest = &convertBuffer[0];
            for(int v=0;v<values;v++)
                dest[v] = src[v] * 10000;
 
            alBufferData(buffer, openAlFormat, dest, values*sizeof(short), rate);
         }
         else
            alBufferData(buffer, openAlFormat, data, size, rate);

         alSourceQueueBuffers(sourceId, 1, &buffer );
 

         if (!playing())
         {
            LOG_SOUND(" kickstart");
            alSourcePlay(sourceId);
         }
      }

      int samples = size/sampleSize;
      if (samples<2048)
         noMoreData = true;
   }

};




// ---   OpenALSound ----------------------------


class OpenALSound : public Sound
{
public:
   ALint bufferSize;
   ALint frequency;
   ALint channels;
   int   samples;
   ALuint mBufferID;
   double duration;

   INmeSoundData *soundData;
   std::string mError;
         
   OpenALSound(const std::string &inFilename, bool inForceMusic)
   {
      init(INmeSoundData::create(inFilename, inForceMusic ? 0 : SoundForceDecode ));
   }

   OpenALSound(const unsigned char *inData, int inLen, bool inForceMusic)
   {
      init(INmeSoundData::create(inData, inLen, inForceMusic ? 0 : SoundForceDecode));
   }

   ~OpenALSound()
   {
      //LOG_SOUND("OpenALSound destructor() ###################################");
      if (mBufferID!=0)
         alDeleteBuffers(1, &mBufferID);
      if (soundData)
         soundData->release();
   }

   const char *getEngine() { return "openal"; }

   void init(INmeSoundData *inData)
   {
      IncRef();
      mBufferID = 0;

      duration = 0.0;
      bufferSize = 0;
      channels = 1;
      samples = 0;
      frequency = 1;
      soundData = inData;

      
      if (!soundData)
      {
         //LOG_SOUND("OpenALSound constructor() error in url");
         mError = "Error opening sound data for openal\n";
      }
      else
      {
         channels = soundData->getIsStereo() ? 2 : 1;
         frequency = soundData->getRate();
         samples = soundData->getChannelSampleCount();
         bufferSize = sizeof(short)*samples*channels;
         duration = soundData->getDuration();

         if (soundData->getIsDecoded())
         {
            int format = soundData->getIsStereo() ?  AL_FORMAT_STEREO16 : AL_FORMAT_MONO16;
         
            // Transfer data to buffer
            alGenBuffers(1, &mBufferID);
            alBufferData(mBufferID,format,
                 soundData->decodeAll(),
                 bufferSize,
                 frequency); 

            // Sucked it dry
            soundData->release();
            soundData = 0;
         }
         else
         {
            // Streaming...
         }
      }
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
   
   double getLength() { return duration*1000.0; }

   void getId3Value(const std::string &inkey, std::string &outvalue) { outvalue=std::string(); }
   
   int getBytesLoaded()
   {
      int toBeReturned = ok() ? 100 : 0;
      //log_sound("openalsound getbytesloaded returning %i", tobereturned);
      return toBeReturned;
   }
   
   int getBytesTotal()
   {
      int tobereturned = ok() ? 100 : 0;
      //log_sound("openalsound getbytestotal returning %i", tobereturned);
      return tobereturned;
   }
   
   
   bool ok() { return mBufferID || soundData; }
   std::string getError() { return mError; }
   void close()
   {
      //LOG_SOUND("OpenALSound close() doing nothing"); 
      if (soundData)
      {
         soundData->release();
         soundData = 0;
      }
   }
   
   
   SoundChannel *openChannel(double startTime, int loops, const SoundTransform &inTransform)
   {
      if (mBufferID)
      {
         return new OpenALBufferChannel(this, inTransform, mBufferID, startTime, loops);
      }
      else if (soundData)
      {
         INmeSoundStream *stream = soundData->createStream();
         if (stream)
            return new OpenALStaticStreamChannel(this, inTransform, stream, startTime, loops);
      }
      return 0;
   }
}; // end OpenALSound
   


// --- External Sound implementation -------------------
   

SoundChannel *CreateOpenAlSyncChannel(const ByteArray &inBytes,const SoundTransform &inTransform,
    SoundDataFormat inDataFormat,bool inIsStereo, int inRate) 
{
   if (!OpenALInit())
      return 0;
   
  OpenALSyncUpdateChannel *result =  new OpenALSyncUpdateChannel(inTransform, inDataFormat, inIsStereo, inRate);
  result->addData(inBytes);
  return result;
}

  

Sound *CreateOpenAlSound(const std::string &inFilename,bool inForceMusic)
{
   //Always check if openal is intitialized
   if (!OpenALInit())
      return 0;
   
   return new OpenALSound(inFilename, inForceMusic);
}


Sound *CreateOpenAlSound(const unsigned char *inData, int len, bool inForceMusic)
{
   //Always check if openal is intitialized
   if (!OpenALInit())
      return 0;

   return new OpenALSound(inData, len, inForceMusic);
}


void SuspendOpenAl()
{
   //Always check if openal is initialized
   if (!OpenALInit())
      return;
   
   alcMakeContextCurrent(0);
   alcSuspendContext(sgContext);
}

void ResumeOpenAl()
{
   //Always check if openal is initialized
   if (!OpenALInit())
      return;
   
   alcMakeContextCurrent(sgContext);

}

void PingOpenAl()
{
   alcProcessContext(sgContext);
}

void ShutdownOpenAl()
{
   OpenALClose();
}





} // end namespace nme
