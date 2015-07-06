#include <SLES/OpenSLES.h>
#include <SLES/OpenSLES_Android.h>
#include <math.h>
#include <Sound.h>
#include <nme/QuickVec.h>
#include <ByteArray.h>
#include <Utils.h>
#include "Audio.h"
#include <NmeThread.h>
//#include <unistd.h>
//#include <sys/time.h>


namespace nme
{


bool opensl_is_init = false;
bool opensl_is_shutdown = false;

SLObjectItf engineObject;
SLEngineItf engineEngine = 0;


bool OpenSlInit()
{
   opensl_is_shutdown = false;

   if (slCreateEngine(&engineObject, 0, NULL, 0, NULL, NULL)==SL_RESULT_SUCCESS &&
         (*engineObject)->Realize(engineObject, SL_BOOLEAN_FALSE)==SL_BOOLEAN_FALSE &&
           (*engineObject)->GetInterface(engineObject, SL_IID_ENGINE, &engineEngine) == SL_RESULT_SUCCESS )
      opensl_is_init = true;

   return opensl_is_init;
}


bool OpenSlClose()
{
   if (opensl_is_init && !opensl_is_shutdown)
   {
      opensl_is_shutdown = true;
      if (engineObject)
          (*engineObject)->Destroy(engineObject);
      engineObject = 0;
      engineEngine = 0;
   }
   return true;
}



class OpenSlSourceChannel : public SoundChannel
{
public:
   Object *soundObject;
   bool   shouldPlay;
   bool   suspended;
   double duration;

   SLObjectItf outputMixObject;
   SLObjectItf bqPlayerObject;
   SLPlayItf bqPlayerPlay;
   SLAndroidSimpleBufferQueueItf bqPlayerBufferQueue;
   //SLEffectSendItf bqPlayerEffectSend;


   OpenSlSourceChannel(Object *inSound, const SoundTransform &inTransform,
          SoundDataFormat inFormat, bool inIsStereo, int inRate, bool inDoubleBuffer )
   {
      soundObject = inSound;
      if (soundObject)
         soundObject->IncRef();

      outputMixObject = 0;
      bqPlayerObject = 0;
      bqPlayerPlay = 0;
      bqPlayerBufferQueue = 0;

      duration = 0.0;
      suspended = false;

      setTransform(inTransform);
      shouldPlay = false;

      int slRate = inRate;
      switch(inRate)
      {
         case 11025: slRate = SL_SAMPLINGRATE_11_025; break;
         case 22050: slRate = SL_SAMPLINGRATE_22_05; break;
         case 44100: slRate = SL_SAMPLINGRATE_44_1; break;
      }


      const SLInterfaceID ids[] = {SL_IID_VOLUME};
      const SLboolean req[] = {SL_BOOLEAN_FALSE};
      if ((*engineEngine)->CreateOutputMix(engineEngine, &outputMixObject, 1, ids, req)==SL_RESULT_SUCCESS &&
            (*outputMixObject)->Realize(outputMixObject, SL_BOOLEAN_FALSE)==SL_BOOLEAN_FALSE )
      {
         SLDataFormat_PCM pcm;
         pcm.formatType = SL_DATAFORMAT_PCM;
         pcm.numChannels = 1;
         pcm.samplesPerSec = slRate;
         pcm.bitsPerSample = SL_PCMSAMPLEFORMAT_FIXED_16;
         pcm.containerSize = SL_PCMSAMPLEFORMAT_FIXED_16;
         pcm.channelMask = inIsStereo ? SL_SPEAKER_FRONT_LEFT | SL_SPEAKER_FRONT_RIGHT : SL_SPEAKER_FRONT_CENTER;
         pcm.endianness = SL_BYTEORDER_LITTLEENDIAN;

	
         // configure audio source
         // Double buffer or single buffer?
         SLDataLocator_AndroidSimpleBufferQueue loc_bufq;
         loc_bufq.locatorType = SL_DATALOCATOR_ANDROIDSIMPLEBUFFERQUEUE;
         loc_bufq.numBuffers = inDoubleBuffer?2:1;
		
         SLDataSource audioSrc = {&loc_bufq, &pcm};
 
         // configure audio sink
         SLDataLocator_OutputMix loc_outmix = {SL_DATALOCATOR_OUTPUTMIX, outputMixObject};
         SLDataSink audioSnk = {&loc_outmix, NULL};
 
         // create audio player
         const SLInterfaceID ids1[] = {SL_IID_ANDROIDSIMPLEBUFFERQUEUE};
         const SLboolean req1[] = {SL_BOOLEAN_TRUE};
          
         if ( (*engineEngine)->CreateAudioPlayer(engineEngine, &bqPlayerObject, &audioSrc, &audioSnk, 1, ids1, req1)==SL_RESULT_SUCCESS &&
              (*bqPlayerObject)->Realize(bqPlayerObject, SL_BOOLEAN_FALSE) == SL_RESULT_SUCCESS &&
              (*bqPlayerObject)->GetInterface(bqPlayerObject, SL_IID_PLAY, &bqPlayerPlay)==SL_RESULT_SUCCESS  &&
              (*bqPlayerObject)->GetInterface(bqPlayerObject, SL_IID_ANDROIDSIMPLEBUFFERQUEUE, &bqPlayerBufferQueue)==SL_RESULT_SUCCESS &&
              (*bqPlayerBufferQueue)->RegisterCallback(bqPlayerBufferQueue, sOnBufferDone, this)==SL_RESULT_SUCCESS )
         {
            shouldPlay = true;
            play();
         }
      }
   }

   void queueData(const void *inData, int inByteCount)
   {
      if (bqPlayerBufferQueue)
         (*bqPlayerBufferQueue)->Enqueue(bqPlayerBufferQueue,inData,inByteCount);
   }

   virtual void onBufferDone()
   {
   }

   static void sOnBufferDone(SLAndroidSimpleBufferQueueItf, void *inChannel)
   {
       ((OpenSlSourceChannel *)inChannel)->onBufferDone();
   }

   ~OpenSlSourceChannel()
   {
      stop();
   }

   void play()
   {
      if (bqPlayerPlay)
         (*bqPlayerPlay)->SetPlayState(bqPlayerPlay, SL_PLAYSTATE_PLAYING);
   }

   void rewind()
   {
   }
   

   
   void setTransform(const SoundTransform &inTransform)
   {
   }

   bool playing()
   {
      if (opensl_is_shutdown)
         return false;
 
      if (bqPlayerPlay)
      {
         SLuint32 state = SL_PLAYSTATE_STOPPED;
         (*bqPlayerPlay)->GetPlayState(bqPlayerPlay, &state);
         return state==SL_PLAYSTATE_PLAYING;
      }
 
      return false;
   }

   void stop()
   {
      // destroy buffer queue audio player object, and invalidate all associated interfaces
      if (bqPlayerObject)
      {
         SLuint32 state = SL_PLAYSTATE_PLAYING;
         (*bqPlayerPlay)->SetPlayState(bqPlayerPlay, SL_PLAYSTATE_STOPPED);
         while(state != SL_PLAYSTATE_STOPPED)
            (*bqPlayerPlay)->GetPlayState(bqPlayerPlay, &state);
         (*bqPlayerObject)->Destroy(bqPlayerObject);
         bqPlayerObject = 0;
         bqPlayerPlay = 0;
         bqPlayerBufferQueue = 0;
         //bqPlayerEffectSend = 0;
      }
 
      // destroy output mix object, and invalidate all associated interfaces
      if (outputMixObject)
      {
         (*outputMixObject)->Destroy(outputMixObject);
         outputMixObject = 0;
      }
 
      shouldPlay = false;

      clRemoveChannel(this);
   }
   
   
   void suspend()
   {
      suspended = true;
      if (playing())
      {
      }
   }
   
   
   void resume()
   {
      if (shouldPlay)
      {
      }
   }
  
   
   double getLeft()  
   {
      return 0.5;
   }
   
   
   double getRight()   
   {
      return 0.5;
   }
 

   
   double getLength() { return duration*1000.0; }

   double setPosition(const float &inFloat)
   {
      return inFloat;
   }
   
   
   double getPosition() 
   {
      return 0 * 1000.0;
   }

   bool isComplete()
   {
      return true;
   }
};


#if 0




class OpenAudioBufferChannel : public OpenAudioChannel
{
public:
   AudioBuffer bufferId;
   int         byteSize;
   int         loops;

   OpenAudioBufferChannel(Object *inSound, const SoundTransform &inTransform, AudioBuffer &inBufferId, int startTime, int inLoops)
      : OpenAudioChannel(inSound, inTransform )
   {
      int seekToBytes=0;

      bufferId = inBufferId;

      byteSize = getBufferBytes(bufferId);

      duration = getBufferDuration(bufferId);

      loops = inLoops>0 ? inLoops -1 : inLoops;
      bool tooMuchSeek = false;
      if (duration && inSound)
      {
         seekToBytes = ( (startTime*0.001)*byteSize/ duration );
         int seekLoops = seekToBytes/byteSize;
         seekToBytes -= seekLoops*byteSize;
         if (loops>=0)
         {
            loops -= seekLoops;
            if (loops<0)
               tooMuchSeek = true;
         }
     
         seekToBytes & ~0x3; // 2 channels, 16 bit round
      }
     
      
      if (!tooMuchSeek)
      {
         shouldPlay = true;

         queueBuffer(bufferId);

         play();

         if (seekToBytes && seekToBytes<byteSize)
            seekBytes(seekToBytes);

         clAddChannel(this, loops>0);
      }
   }


   ~OpenAudioBufferChannel()
   {
      stop();
   }

   void stop()
   {
      OpenAudioChannel::stop();
      loops = 0;
   }

   void asyncUpdate()
   {
      if (!playing() && loops!=0)
      {
         rewind();
         play();
         if (loops>0)
            loops--;
      }
   }

   bool isComplete()
   {
      return !opensl_is_shutdown && !loops && !playing();
   }

};






class OpenALDoubleBufferChannel : public OpenAudioChannel
{
public:
   ALuint  bufferIds[2];

   NmeMutex bufferMutex;
   ALuint   freeBuffers[2];
   int      freeBufferCount;

   OpenALDoubleBufferChannel(Object *inSound, const SoundTransform &inTransform)
      : OpenAudioChannel(inSound, inTransform )
   {
      bufferIds[0] = bufferIds[1] = 0;
      freeBufferCount = 0;
  }

   void createBuffers()
   {
      alGenBuffers(2, bufferIds);
      freeBuffers[ freeBufferCount++ ] = bufferIds[0];
      freeBuffers[ freeBufferCount++ ] = bufferIds[1];
      check("alGenBuffers");
   }


   void stop()
   {
      OpenAudioChannel::stop();

      if (opensl_is_shutdown)
         return;

      if (bufferIds[0])
         alDeleteBuffers(2, bufferIds);
       freeBufferCount = 0;
   }
  
   void unqueueBuffers()
   {
      int processed = 0;
      alGetSourcei(sourceId, AL_BUFFERS_PROCESSED, &processed);
      while(processed--)
      {
         ALuint buffer = 0;
         alSourceUnqueueBuffers(sourceId, 1, &buffer);

         addFreeBuffer(buffer);
      }
   }



   ALuint getFreeBuffer()
   {
      if (opensl_is_shutdown || suspended)
         return 0;

      int processed = 0;
      alGetSourcei(sourceId, AL_BUFFERS_PROCESSED, &processed);
      if (processed>0)
      {
         ALuint result = 0;
         alSourceUnqueueBuffers(sourceId, 1, &result);
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
   bool isComplete()
   {
      return !opensl_is_shutdown && !shouldPlay;
   }

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
      if (opensl_is_shutdown || !shouldPlay || suspended)
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
               stream->setPosition(skip);

            shouldPlay = true;
            if (updateStream())
            {
               clAddChannel(this,true);
            }
            else
               shouldPlay = false;
         }
      }
   }

   bool isComplete()
   {
      return !opensl_is_shutdown && freeBufferCount==2;
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
      shouldPlay = true;
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
      if (opensl_is_shutdown || !shouldPlay || suspended || syncDataPending || noMoreData )
         return false;

      unqueueBuffers();

      if (freeBufferCount==0)
         return false;

      return true;
   }

   bool isComplete()
   {
      if (opensl_is_shutdown)
         return false;
      if (noMoreData)
      {
         if (freeBufferCount<2)
            unqueueBuffers();
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




// ---   OpenSlSound ----------------------------


class OpenSlSound : public Sound
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
         
   OpenSlSound(const std::string &inFilename, bool inForceMusic)
   {
      init(INmeSoundData::create(inFilename, inForceMusic ? 0 : SoundForceDecode ));
   }

   OpenSlSound(const unsigned char *inData, int inLen)
   {
      init(INmeSoundData::create(inData, inLen, 0));
   }

   ~OpenSlSound()
   {
      //LOG_SOUND("OpenSlSound destructor() ###################################");
      if (mBufferID!=0)
         alDeleteBuffers(1, &mBufferID);
      if (soundData)
         soundData->release();
   }


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
         //LOG_SOUND("OpenSlSound constructor() error in url");
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
      if (opensl_is_shutdown) return;
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
      //log_sound("OpenSlSound getbytesloaded returning %i", tobereturned);
      return toBeReturned;
   }
   
   int getBytesTotal()
   {
      int tobereturned = ok() ? 100 : 0;
      //log_sound("OpenSlSound getbytestotal returning %i", tobereturned);
      return tobereturned;
   }
   
   
   bool ok() { return mBufferID || soundData; }
   std::string getError() { return mError; }
   void close()
   {
      //LOG_SOUND("OpenSlSound close() doing nothing"); 
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
         return new OpenAudioBufferChannel(this, inTransform, mBufferID, startTime, loops);
      }
      else if (soundData)
      {
         INmeSoundStream *stream = soundData->createStream();
         if (stream)
            return new OpenALStaticStreamChannel(this, inTransform, stream, startTime, loops);
      }
      return 0;
   }
}; // end OpenSlSound
   


// --- External Sound implementation -------------------
   
#endif


SoundChannel *SoundChannel::CreateSyncChannel(const ByteArray &inBytes,const SoundTransform &inTransform,
    SoundDataFormat inDataFormat,bool inIsStereo, int inRate) 
{
   if (!OpenSlInit())
      return 0;
   
  OpenSlSourceChannel *result =  new OpenSlSourceChannel(0,inTransform, inDataFormat, inIsStereo, inRate, true);
  result->addData(inBytes);
  return result;
}

#if 0

Sound *Sound::Create(const std::string &inFilename,bool inForceMusic)
{
   //Always check if openal is intitialized
   if (!OpenSlInit())
      return 0;
   
   //Return a reference
   OpenSlSound *sound = 0;
   
   if (!inForceMusic)
   {
      ByteArray bytes = AndroidGetAssetBytes(inFilename.c_str());
      sound = new OpenSlSound((char *)bytes.Bytes(), bytes.Size());
   }
   else
   {
      sound = new OpenSlSound(inFilename, inForceMusic);
   }
   
   if (sound->ok ())
      return sound;
   else
      return 0;
}


Sound *Sound::Create(float *inData, int len, bool inForceMusic)
{
   //Always check if openal is intitialized
   if (!OpenSlInit())
      return 0;

   //Return a reference
   OpenSlSound *sound = new OpenSlSound((const unsigned  char*)inData, len);
   
   if (sound->ok ())
      return sound;
   else
      return 0;
}


void Sound::Suspend()
{
   //Always check if openal is initialized
   if (!OpenSLinit())
      return;
   
   clSuspendAllChannels();
}


void Sound::Resume()
{
   //Always check if openal is initialized
   if (!OpenSlInit())
      return;
   
   clResumeAllChannels();
}


void Sound::Shutdown()
{
   OpenSlClose();
}

     
Sound *Sound::CreateOpenSl(const std::string &inFilename, bool inForceMusic)
{
   if (!OpenSlInit())
      return 0;
   return new OpenSlSound(inFilename, inForceMusic);
}

Sound *Sound::CreateOpenSl(float *inData, int len)
{
   if (!OpenSlInit())
      return 0;
   return new OpenSlSound((const unsigned char *)inData, len);
}

#endif



} // end namespace nme
