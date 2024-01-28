#include <SLES/OpenSLES.h>
#include <SLES/OpenSLES_Android.h>
#include <math.h>
#include <Sound.h>
#include <nme/QuickVec.h>
#include <ByteArray.h>
#include <Utils.h>
#include "Audio.h"
#include <NMEThread.h>
#include <dlfcn.h>
//#include <unistd.h>
//#include <sys/time.h>


namespace nme
{

typedef SLresult (*slCreateEngine_func)(
        SLObjectItf*, SLuint32, const SLEngineOption*, SLuint32,
        const SLInterfaceID*, const SLboolean*);

slCreateEngine_func slDynamicCreateEngine = 0;
SLInterfaceID iidAndroidSampleBuffer = 0;
SLInterfaceID iidPlay = 0;
SLInterfaceID iidEngine = 0;
SLInterfaceID iidVolume = 0;


bool opensl_is_init = false;
bool opensl_is_shutdown = false;

SLObjectItf engineObject;
SLEngineItf engineEngine = 0;


SLInterfaceID findInterface(void *dll, const char *inName)
{
   SLInterfaceID *symPtr = (SLInterfaceID *)dlsym(dll,inName);
   if (!symPtr)
   {
      ELOG("Could not find symbol %s", inName);
      return 0;
   }
   VLOG(" got interface %s = %d", inName, *symPtr);
   return *symPtr;
}

bool OpenSlInit()
{
   if (!slDynamicCreateEngine)
   {
      void *dll = dlopen("libOpenSLES.so", RTLD_NOW);
      VLOG("OpenSlInit %p", dll);
      if (dll)
      {
         slDynamicCreateEngine = (slCreateEngine_func)dlsym(dll,"slCreateEngine");
         VLOG("OpenSlInit slDynamicCreateEngine = %p", slDynamicCreateEngine);
         iidAndroidSampleBuffer = findInterface(dll, "SL_IID_ANDROIDSIMPLEBUFFERQUEUE");
         iidPlay = findInterface(dll, "SL_IID_PLAY");
         iidEngine = findInterface(dll, "SL_IID_ENGINE");
         iidVolume = findInterface(dll, "SL_IID_VOLUME");
      }
   }

   if (slDynamicCreateEngine && iidAndroidSampleBuffer && iidPlay && iidEngine && iidVolume)
   {
      LOG_SOUND("ooooo OpenSlInit Good.");
      opensl_is_shutdown = false;

      if (slDynamicCreateEngine(&engineObject, 0, NULL, 0, NULL, NULL)==SL_RESULT_SUCCESS &&
            (*engineObject)->Realize(engineObject, SL_BOOLEAN_FALSE)==SL_BOOLEAN_FALSE &&
              (*engineObject)->GetInterface(engineObject, iidEngine, &engineEngine) == SL_RESULT_SUCCESS )
         opensl_is_init = true;
   }
   if (!opensl_is_init)
      ELOG("OpenSlInit Bad.");

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
   double t0;
   int    frequency;
   int    channels;

   SLObjectItf outputMixObject;
   SLObjectItf bqPlayerObject;
   SLPlayItf bqPlayerPlay;
   SLAndroidSimpleBufferQueueItf bqPlayerBufferQueue;
   SLVolumeItf bqPlayerVolume;
   //SLEffectSendItf bqPlayerEffectSend;


   OpenSlSourceChannel(Object *inSound, const SoundTransform &inTransform,
          SoundDataFormat inFormat, bool inIsStereo, int inRate, bool inDoubleBuffer )
   {
      frequency = inRate;
      channels = inIsStereo ? 2 : 1;
      soundObject = inSound;
      if (soundObject)
         soundObject->IncRef();

      outputMixObject = 0;
      bqPlayerObject = 0;
      bqPlayerPlay = 0;
      bqPlayerBufferQueue = 0;
      bqPlayerVolume = 0;

      t0 = 0.0;
      duration = 0.0;
      suspended = false;

      setTransform(inTransform);
      shouldPlay = false;

      int slRate = inRate*1000;
      switch(inRate)
      {
         case 11025: slRate = SL_SAMPLINGRATE_11_025; break;
         case 22050: slRate = SL_SAMPLINGRATE_22_05; break;
         case 44100: slRate = SL_SAMPLINGRATE_44_1; break;
      }
      
      const SLInterfaceID ids[] = {iidVolume};
      const SLboolean req[] = {SL_BOOLEAN_FALSE};
      if ((*engineEngine)->CreateOutputMix(engineEngine, &outputMixObject, 1, ids, req)==SL_RESULT_SUCCESS &&
            (*outputMixObject)->Realize(outputMixObject, SL_BOOLEAN_FALSE)==SL_RESULT_SUCCESS )
      {
         SLDataFormat_PCM pcm;
         pcm.formatType = SL_DATAFORMAT_PCM;
         pcm.numChannels = inIsStereo ? 2 : 1;
         pcm.samplesPerSec = slRate;
         pcm.bitsPerSample = SL_PCMSAMPLEFORMAT_FIXED_16;
         pcm.channelMask = inIsStereo ? SL_SPEAKER_FRONT_LEFT | SL_SPEAKER_FRONT_RIGHT : SL_SPEAKER_FRONT_CENTER;
         pcm.endianness = SL_BYTEORDER_LITTLEENDIAN;

         switch(inFormat)
         {
            case sdfByte: pcm.bitsPerSample = SL_PCMSAMPLEFORMAT_FIXED_8; break;
            case sdfShort:
            case sdfFloat:
               pcm.bitsPerSample = SL_PCMSAMPLEFORMAT_FIXED_16;
               break;
         }
         pcm.containerSize = pcm.bitsPerSample;

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
         const SLInterfaceID ids1[] = {iidAndroidSampleBuffer, iidVolume};
         const SLboolean req1[] = {SL_BOOLEAN_TRUE};
         if ( (*engineEngine)->CreateAudioPlayer(engineEngine, &bqPlayerObject, &audioSrc, &audioSnk, 2, ids1, req1)==SL_RESULT_SUCCESS &&
              (*bqPlayerObject)->Realize(bqPlayerObject, SL_BOOLEAN_FALSE) == SL_RESULT_SUCCESS &&
              (*bqPlayerObject)->GetInterface(bqPlayerObject, iidPlay, &bqPlayerPlay)==SL_RESULT_SUCCESS  &&
              (*bqPlayerObject)->GetInterface(bqPlayerObject, iidAndroidSampleBuffer, &bqPlayerBufferQueue)==SL_RESULT_SUCCESS &&
              (*bqPlayerObject)->GetInterface(bqPlayerObject, iidVolume, &bqPlayerVolume)==SL_RESULT_SUCCESS &&
              (*bqPlayerBufferQueue)->RegisterCallback(bqPlayerBufferQueue, sOnBufferDone, this)==SL_RESULT_SUCCESS )
         {
            shouldPlay = true;
            play();
         }
         else
            ELOG("Could not create valid audio player");
      }
      else
         ELOG("Could not create outputMixObject");
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
      if (soundObject) 
         soundObject->DecRef();
   }

   void play()
   {
      if (bqPlayerPlay)
         (*bqPlayerPlay)->SetPlayState(bqPlayerPlay, SL_PLAYSTATE_PLAYING);
   }

   void rewind()
   {
   }
   

   float gain_to_attenuation( float gain )
   {
      // gain 0.7 -> -300 mdb attenuation
      // gain 0.5 -> -600 mdb attenuation
      // gain 0.35-> -900 mdb attenuation
      if (gain==1)
         return 0;
      if (gain<0.01)
         return SL_MILLIBEL_MIN;

      return -300.0 * log(gain)/log(0.7);
   }

   
   void setTransform(const SoundTransform &inTransform)
   {
      float attenuation = gain_to_attenuation(inTransform.volume);

      LOG_SOUND("setTransform %p attenuation=%f -> %f pan=%f", bqPlayerPlay, inTransform.volume, attenuation, inTransform.pan);
      if (bqPlayerVolume)
      {
         (*bqPlayerVolume)->SetVolumeLevel(bqPlayerVolume, attenuation);

         if (inTransform.pan!=0.0)
         {
            (*bqPlayerVolume)->EnableStereoPosition(bqPlayerVolume, true);
            SLpermille value = inTransform.pan*1000;
            (*bqPlayerVolume)->SetStereoPosition(bqPlayerVolume, value);
         }
      }
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
         if (bqPlayerPlay) 
         {
            (*bqPlayerPlay)->SetPlayState(bqPlayerPlay, SL_PLAYSTATE_STOPPED);
            while(state != SL_PLAYSTATE_STOPPED)
                  (*bqPlayerPlay)->GetPlayState(bqPlayerPlay, &state);
         }
         (*bqPlayerObject)->Destroy(bqPlayerObject);
         bqPlayerObject = 0;
         bqPlayerPlay = 0;
         bqPlayerBufferQueue = 0;
         bqPlayerVolume = 0;
         //bqPlayerEffectSend = 0;
      }
 
      // destroy output mix object, and invalidate all associated interfaces
      if (outputMixObject)
      {
         (*outputMixObject)->Destroy(outputMixObject);
         outputMixObject = 0;
      }
 
      LOG_SOUND("Stop %p!", this);
      shouldPlay = false;

      clRemoveChannel(this);
   }
   
   
   void suspend()
   {
      LOG_SOUND("Suspend %p!", this);
      suspended = true;
      shouldPlay = playing();
      if (shouldPlay)
      {
         LOG_SOUND(" -> pause");
        if (bqPlayerPlay) 
        { 
           (*bqPlayerPlay)->SetPlayState(bqPlayerPlay, SL_PLAYSTATE_PAUSED);
        }
      }
   }
   
   
   void resume()
   {
      LOG_SOUND("Resume %p (%d)!", this, shouldPlay);
      if (shouldPlay)
      {
         LOG_SOUND(" -> play");
         if (bqPlayerPlay) 
         { 
           (*bqPlayerPlay)->SetPlayState(bqPlayerPlay, SL_PLAYSTATE_PLAYING);
         }
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
      if ( bqPlayerPlay )
      {
         SLmillisecond nPositionMs = 0; 
         (*bqPlayerPlay)->GetPosition( bqPlayerPlay, &nPositionMs ); 
         return nPositionMs + t0*1000.0;
      }
      return 0.0;
   }

   bool isComplete()
   {
      return true;
   }
};


class OpenSlDoubleBufferChannel : public OpenSlSourceChannel
{
public:

   std::vector<unsigned char> sampleBuffer[2];
   volatile int activeBuffers;
   int  writeBuffer;



   OpenSlDoubleBufferChannel(Object *inSound,const SoundTransform &inTransform,SoundDataFormat inFormat, bool inIsStereo, int inRate)
      : OpenSlSourceChannel(inSound, inTransform, inFormat, inIsStereo, inRate, true )
   {
      LOG_SOUND("Create doubleBUffer channel");
      activeBuffers = 0;
      writeBuffer = 0;
   }

   void onBufferDone()
   {
      __sync_fetch_and_sub(&activeBuffers,1);
   }


   std::vector<unsigned char> &allocBuffer()
   {
       __sync_fetch_and_add(&activeBuffers,1);
      LOG_SOUND("Writing to buffer %d/%d", writeBuffer, activeBuffers);
      std::vector<unsigned char> & result = sampleBuffer[writeBuffer];
      writeBuffer = !writeBuffer;
      return result;
   }

};







class OpenSlSyncUpdateChannel : public OpenSlDoubleBufferChannel
{
public:
   SoundDataFormat dataFormat;
   bool syncDataPending;
   bool noMoreData;
   bool isStereo;
   int  sampleSize;

   

   OpenSlSyncUpdateChannel(const ByteArray &inBytes,const SoundTransform &inTransform,SoundDataFormat inFormat, bool inIsStereo, int inRate)
      : OpenSlDoubleBufferChannel(0, inTransform, inFormat, inIsStereo, inRate  )
   {
      syncDataPending = false;
      noMoreData = false;
      isStereo = inIsStereo;
      dataFormat = inFormat;
      sampleSize = 0;

      if (shouldPlay)
      {
         switch(dataFormat)
         {
            case sdfByte: sampleSize = isStereo ? 2 : 1; break;
            case sdfShort: sampleSize = isStereo ? 4 : 2; break;
            case sdfFloat: sampleSize = isStereo ? 8 : 4; break;
         }

         addData(inBytes);

         clAddChannel(this, false);
      }
   }



   bool needsData()
   {
      if (opensl_is_shutdown || !shouldPlay || suspended || syncDataPending || noMoreData )
         return false;

      return activeBuffers<2;
   }

   bool isComplete()
   {
      if (opensl_is_shutdown)
         return false;
      if (noMoreData)
         return !playing();

      return false;
   }

   void addData(const ByteArray &inBytes)
   {
      const unsigned char *data = inBytes.Bytes();
      int size = inBytes.Size();

      if (size>0)
      {
         std::vector<unsigned char> &buffer = allocBuffer();
         if (dataFormat==sdfFloat)
         {
            int values = size/sizeof(float);
            float *src = (float *)data;

            buffer.resize(values*sizeof(short));
            short *dest = (short *)&buffer[0];
            for(int v=0;v<values;v++)
                dest[v] = src[v] * 16383.0;
         }
         else
         {
            buffer.resize(size);
            memcpy(&buffer[0], data, size);
         }
         queueData(&buffer[0], buffer.size());
      }

      int samples = size/sampleSize;
      if (samples<2048)
         noMoreData = true;
   }

};








class OpenSlBufferChannel : public OpenSlSourceChannel
{
public:
   int         loops;
   int         byteCount;
   INmeSoundData *data;


   OpenSlBufferChannel(Object *inSound, const SoundTransform &inTransform, INmeSoundData *inData, double startTime, int inLoops)
      : OpenSlSourceChannel(inSound, inTransform, 
                     sdfShort, inData->getIsStereo(), inData->getRate(), false )
   {
      data = inData;
      duration = inData->getDuration();
      const unsigned char *decoded = (const unsigned char *)data->decodeAll();
      byteCount = data->getDecodedByteCount();

      loops = inLoops>0 ? inLoops -1 : inLoops;

      bool tooMuchSeek = false;
      int  seekBytes = 0;
      if (byteCount && startTime)
      {
         seekBytes = (int)( (startTime * 0.001) * (frequency*channels*sizeof(short))) & ~3;
         int seekLoops = seekBytes/byteCount;
         if (loops>=0)
         {
            loops -= seekLoops;
            if (loops<0)
               tooMuchSeek = true;
         }
      }

      LOG_SOUND("OpenSlSourceChannel size=%d seek=%d", byteCount, seekBytes);
     
      
      if (!tooMuchSeek)
      {
         t0 = (double)seekBytes / (frequency*channels*sizeof(short));
         queueData( decoded + seekBytes, byteCount - seekBytes );
         clAddChannel(this, loops>0);
      }
   }


   ~OpenSlBufferChannel()
   {
      stop();
   }

   void stop()
   {
      OpenSlSourceChannel::stop();
      loops = 0;
   }

   void asyncUpdate()
   {
   }

   void onBufferDone()
   {
      LOG_SOUND("onBufferDone asyncUpdate %d %d %f", playing(), loops, getPosition() );
      t0 = 0;
      if (loops!=0)
      {
         queueData( data->decodeAll(), data->getDecodedByteCount() );
         if (loops>0)
            loops--;
         if (!playing())
            play();
         else
            t0 = -0.001*getPosition();
      }
   }


   bool isComplete()
   {
      return !opensl_is_shutdown && !loops && !playing();
   }

};






class OpenSlStreamChannel : public OpenSlDoubleBufferChannel
{
public:
   INmeSoundStream *stream;
   int             loops;
   bool            priming;

   OpenSlStreamChannel(Object *inSound, const SoundTransform &inTransform, INmeSoundStream *inStream, int startTime, int inLoops)
      : OpenSlDoubleBufferChannel(inSound, inTransform, sdfShort, inStream->getIsStereo(), inStream->getRate()  )
   {
      stream = inStream;

      loops = inLoops >0 ? inLoops-1 : inLoops;
      duration = stream->getDuration();
      bool tooMuchSeek = false;

      duration = stream->getDuration();
      LOG_SOUND("Play stream duration %f, start %d", duration, startTime);
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
            if (skip)
            {
               t0 = stream->setPosition(skip);
            }

            priming = true;
            LOG_SOUND("Priming 0...");
            streamBuffer();
            if (shouldPlay)
            {
               LOG_SOUND("Priming 1...");
               streamBuffer();
            }
            LOG_SOUND("Priming done");
            priming = false;
         }
      }
   }


   void stop()
   {
      LOG_SOUND("Stop streaming sound");
      OpenSlDoubleBufferChannel::stop();
      if (stream)
      {
         delete stream;
         stream = 0;
      }
   }

   void onBufferDone()
   {
      __sync_fetch_and_sub(&activeBuffers,1);
      LOG_SOUND("onBufferDone -> %d", activeBuffers);
      if (!priming)
         streamBuffer();
   }

   // Returns if the stream still has data.
   void streamBuffer()
   {
      if (!shouldPlay || !stream || opensl_is_shutdown)
         return;

      LOG_SOUND("Fill buffer...");

      std::vector<unsigned char> &buffer = allocBuffer();
      int bytes = ( (stream->getIsStereo() ? 4 : 2) * stream->getRate() * 250/1000 ) & ~7;
      buffer.resize(bytes);
      int size = 0;
      int emptyBuffersCount = 0;

      while(size<bytes)
      {
          int filled = stream->fillBuffer((char *)&buffer[size], bytes-size);
           
          if (filled <= 0)
          {
             if (!tryAgainOnEmptyBuffer(emptyBuffersCount++))
             {
                LOG_SOUND("Stream empty");
                break;
             }
          }
          else
          {
             emptyBuffersCount = 0;
             size += filled;
          }
      }

      if (size==0)
         return;

      LOG_SOUND("Filled %d bytes", size);

      queueData( &buffer[0], size );
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


#if 0



class OpenALStaticStreamChannel : public OpenALStreamChannel
{
public:
   int  loops;

   OpenALStaticStreamChannel(Object *inSound, const SoundTransform &inTransform, INmeSoundStream *inStream, double startTime, int inLoops)
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






#endif



// ---   OpenSlSound ----------------------------


class OpenSlSound : public Sound
{
public:
   INmeSoundData *soundData;
   std::string mError;
   double  duration;
   int     channels;
   int     samples;
   int     frequency;
   int     bufferSize;
         
   OpenSlSound(const unsigned char *inData, int inLen, bool inForceMusic)
   {
		LOG_SOUND("Create OpenSlSound from data %d.\n", inLen)
      init(INmeSoundData::create(inData, inLen, inForceMusic ? 0 : SoundForceDecode));
   }

   ~OpenSlSound()
   {
      if (soundData)
         soundData->release();
   }


   void init(INmeSoundData *inData)
   {
      IncRef();

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

		   LOG_SOUND("Init OpenSlSound with samples %d.\n", samples)
      }
   }
  
   const char *getEngine() { return "opensl"; }

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
   
   
   bool ok() { return soundData; }
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
      if (soundData && soundData->getIsDecoded())
      {
         return new OpenSlBufferChannel(this, inTransform, soundData, startTime, loops);
      }
      else if (soundData)
      {
         ELOG("soundData, but not decoded");
         INmeSoundStream *stream = soundData->createStream();
         if (stream)
            return new OpenSlStreamChannel(this, inTransform, stream, startTime, loops);
      }
      return 0;
   }
}; // end OpenSlSound
   


// --- External Sound implementation -------------------
   


SoundChannel *CreateOpenSlSyncChannel(const ByteArray &inBytes,const SoundTransform &inTransform,
    SoundDataFormat inDataFormat,bool inIsStereo, int inRate) 
{
   if (!OpenSlInit())
      return 0;
   
  OpenSlSyncUpdateChannel *result =  new OpenSlSyncUpdateChannel(inBytes, inTransform, inDataFormat, inIsStereo, inRate);

  return result;
}


Sound *CreateOpenSlSound(const unsigned char *inData, int len, bool inForceMusic)
{
   //Always check if openal is intitialized
   if (!OpenSlInit())
      return 0;

   //Return a reference
   OpenSlSound *sound = new OpenSlSound(inData, len, inForceMusic);

   LOG_SOUND("CreateOpenSlSound %p (%d)", sound, sound->ok() );
   
   if (sound->ok())
      return sound;

   sound->DecRef();
   return 0;
}



} // end namespace nme
