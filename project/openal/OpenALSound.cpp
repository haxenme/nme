#include "OpenALSound.h"


namespace nme
{  
   
   OpenALChannel::OpenALChannel(Object *inSound, ALuint inBufferID, int startTime, int inLoops, const SoundTransform &inTransform)
   {
      //LOG_SOUND("OpenALChannel constructor %d",inBufferID);
      mSound = inSound;
      inSound->IncRef();
      mSourceID = 0;
      mDynamicDone = true;
      mDynamicBuffer[0] = 0;
      mDynamicBuffer[1] = 0;
      mDynamicStackSize = 0;
      mWasPlaying = false;
      mSampleBuffer = 0;
      float seek = 0;
      int size = 0;
      
      if (inBufferID>0)
      {
         // grab a source ID from openAL
         alGenSources(1, &mSourceID);
         
         // attach the buffer to the source
         alSourcei(mSourceID, AL_BUFFER, inBufferID);
         // set some basic source prefs
         alSourcef(mSourceID, AL_PITCH, 1.0f);
         alSourcef(mSourceID, AL_GAIN, inTransform.volume);
         alSource3f(mSourceID, AL_POSITION, inTransform.pan * 1, 0, 0);
         // TODO: not right!
         if (inLoops>1)
            alSourcei(mSourceID, AL_LOOPING, AL_TRUE);
         
         if (startTime > 0)
         {
            ALint bits, channels, freq;
            alGetBufferi(inBufferID, AL_SIZE, &size);
            alGetBufferi(inBufferID, AL_BITS, &bits);
            alGetBufferi(inBufferID, AL_CHANNELS, &channels);
            alGetBufferi(inBufferID, AL_FREQUENCY, &freq);
            int length = (ALfloat)((ALuint)size/channels/(bits/8)) / (ALfloat)freq;
            seek = (startTime * 0.001) / length;
         }
         
         if (seek < 1)
         {
            //alSourceQueueBuffers(mSourceID, 1, &inBufferID);
            alSourcePlay(mSourceID);
            alSourcef(mSourceID, AL_BYTE_OFFSET, seek * size);
         }
         
         mWasPlaying = true;
         sgOpenChannels.push_back((intptr_t)this);
      }
   }
   
   
   OpenALChannel::OpenALChannel(const ByteArray &inBytes,const SoundTransform &inTransform)
   {
      //LOG_SOUND("OpenALChannel dynamic %d",inBytes.Size());
      mSound = 0;
      mSourceID = 0;
      
      mDynamicBuffer[0] = 0;
      mDynamicBuffer[1] = 0;
      mDynamicStackSize = 0;
      mSampleBuffer = 0;
      mWasPlaying = true;
      
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
         alSource3f(mSourceID, AL_POSITION, inTransform.pan * 1, 0, 0);
         
         alSourcePlay(mSourceID);
      }
      
      //sgOpenChannels.push_back((intptr_t)this);
   }
   
   
   void OpenALChannel::QueueBuffer(ALuint inBuffer, const ByteArray &inBytes)
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
   
   
   void OpenALChannel::unqueueBuffers()
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
   
   
   bool OpenALChannel::needsData()
   {
      if (!mDynamicBuffer[0] || mDynamicDone)
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
   
   
   void OpenALChannel::addData(const ByteArray &inBytes)
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
      {
         ALint val = 0;
         alGetSourcei(mSourceID, AL_SOURCE_STATE, &val);
         if(val != AL_PLAYING)
         {
            //LOG_SOUND("Kickstart (%d/%d)",val,mDynamicStackSize);
            
            // This is an indication that the previous buffer finished playing before we could deliver the new buffer.
            // You will hear ugly popping noises...
            alSourcePlay(mSourceID);
         }
      }
   }
   
   
   OpenALChannel::~OpenALChannel()
   {
      //LOG_SOUND("OpenALChannel destructor");
      if (mSourceID)
         alDeleteSources(1, &mSourceID);
      if (mDynamicBuffer[0])
         alDeleteBuffers(2, mDynamicBuffer);
      delete [] mSampleBuffer;
      if (mSound)
         mSound->DecRef();
      
      for (int i = 0; i < sgOpenChannels.size(); i++)
      {
         if (sgOpenChannels[i] == (intptr_t)this)
         {
            sgOpenChannels.erase (i, 1);
            break;
         }
      }
   }
   
   
   bool OpenALChannel::isComplete()
   {
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
      /*
       Possible values of state
       AL_INITIAL
       AL_STOPPED
       AL_PLAYING
       AL_PAUSED
       */
      if(state == AL_STOPPED)
      {
         //LOG_SOUND("OpenALChannel isComplete() returning true");
         return true;
      }
      else
      {
         //LOG_SOUND("OpenALChannel isComplete() returning false");
         return false;
      }
   }
   
   
   double OpenALChannel::getLeft()  
   { 
      float panX=0;
      float panY=0;
      float panZ=0;
      alGetSource3f(mSourceID, AL_POSITION, &panX, &panY, &panZ);
      return (1-panX)/2;
   }
   
   
   double OpenALChannel::getRight()   
   {
      float panX=0;
      float panY=0;
      float panZ=0;
      alGetSource3f(mSourceID, AL_POSITION, &panX, &panY, &panZ);
      return (panX+1)/2;
   }
   
   
   double OpenALChannel::setPosition(const float &inFloat)  {
      alSourcef(mSourceID,AL_SEC_OFFSET,inFloat);
      return inFloat;
   }
   
   
   double OpenALChannel::getPosition() 
   {
      float pos = 0;
      alGetSourcef(mSourceID, AL_SEC_OFFSET, &pos);
      return pos * 1000.0;
   }
   
   
   void OpenALChannel::setTransform(const SoundTransform &inTransform)
   {
      alSourcef(mSourceID, AL_GAIN, inTransform.volume);
      alSource3f(mSourceID, AL_POSITION, inTransform.pan * 1, 0, 0);
   }
   
   
   void OpenALChannel::stop()
   {
      ALint state;
      alGetSourcei(mSourceID, AL_SOURCE_STATE, &state);
      
      if (state == AL_PLAYING)
      {
         mWasPlaying = true;
         alSourceStop(mSourceID);
      }
      
      mWasPlaying = false;
   }
   
   
   void OpenALChannel::pause()
   {
      ALint state;
      alGetSourcei(mSourceID, AL_SOURCE_STATE, &state);
      
      if (state == AL_PLAYING)
      {
         alSourcePause(mSourceID);
         mWasPlaying = true;
         return;
      }
      
      mWasPlaying = false;
   }
   
   
   void OpenALChannel::resume()
   {
      if (mWasPlaying)
      {
         alSourcePlay(mSourceID);
      }
   }
   
   
   SoundChannel *SoundChannel::Create(const ByteArray &inBytes,const SoundTransform &inTransform)
   {
      if (!OpenALInit())
         return 0;
      
      return new OpenALChannel(inBytes, inTransform);
   }
   
   
   OpenALSound::OpenALSound(const std::string &inFilename)
   {
      IncRef();
      mBufferID = 0;
      
      #ifdef HX_MACOS
      char fileURL[1024];
      GetBundleFilename(inFilename.c_str(),fileURL,1024);
      #else
      #ifdef IPHONE
      std::string asset = GetResourcePath() + gAssetBase + inFilename;
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

            //Determine the file format before we try anything
         AudioFormat type = Audio::determineFormatFromFile(std::string(fileURL));

         switch(type) {
            case eAF_ogg:
               ok = Audio::loadOggSampleFromFile( fileURL, buffer, &_channels, &_bitsPerSample, &freq );
            break;
            case eAF_wav:
               ok = Audio::loadWavSampleFromFile( fileURL, buffer, &_channels, &_bitsPerSample, &freq );
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
          
         
         if (!ok) {
            LOG_SOUND("Error opening sound data\n");
            mError = "Error opening sound data";
         } else if (alGetError() != AL_NO_ERROR) {
            LOG_SOUND("Error after opening sound data\n");
            mError = "Error after opening sound data";  
         } else {
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
   
   
   OpenALSound::OpenALSound(float *inData, int len)
   {
      IncRef();
      mBufferID = 0;
      
      QuickVec<uint8> buffer;
      int _channels;
      int _bitsPerSample;
      ALenum  format;
      ALsizei freq;
      bool ok = false; 
      
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
       
      
      if (!ok) {
         LOG_SOUND("Error opening sound data\n");
         mError = "Error opening sound data";
      } else if (alGetError() != AL_NO_ERROR) {
         LOG_SOUND("Error after opening sound data\n");
         mError = "Error after opening sound data";  
      } else {
            // grab a buffer ID from openAL
         alGenBuffers(1, &mBufferID);
         
            // load the awaiting data blob into the openAL buffer.
         alBufferData(mBufferID,format,&buffer[0],buffer.size(),freq); 

            // once we have all our information loaded, get some extra flags
         alGetBufferi(mBufferID, AL_SIZE, &bufferSize);
         alGetBufferi(mBufferID, AL_FREQUENCY, &frequency);
         alGetBufferi(mBufferID, AL_CHANNELS, &channels);    
         alGetBufferi(mBufferID, AL_BITS, &bitsPerSample); 
         
      }
   }
   
   
   OpenALSound::~OpenALSound()
   {
      //LOG_SOUND("OpenALSound destructor() ###################################");
      if (mBufferID!=0)
         alDeleteBuffers(1, &mBufferID);
   }
   
   
   double OpenALSound::getLength()
   {
      double result = ((double)bufferSize) / (frequency * channels * (bitsPerSample/8) );

      //LOG_SOUND("OpenALSound getLength returning %f", toBeReturned);
      return result;
   }
   
   
   void OpenALSound::getID3Value(const std::string &inKey, std::string &outValue)
   {
      //LOG_SOUND("OpenALSound getID3Value returning empty string");
      outValue = "";
   }
   
   
   int OpenALSound::getBytesLoaded()
   {
      int toBeReturned = ok() ? 100 : 0;
      //LOG_SOUND("OpenALSound getBytesLoaded returning %i", toBeReturned);
      return toBeReturned;
   }
   
   
   int OpenALSound::getBytesTotal()
   {
      int toBeReturned = ok() ? 100 : 0;
      //LOG_SOUND("OpenALSound getBytesTotal returning %i", toBeReturned);
      return toBeReturned;
   }
   
   
   bool OpenALSound::ok()
   {
      bool toBeReturned = mError.empty();
      //LOG_SOUND("OpenALSound ok() returning BOOL = %@\n", (toBeReturned ? @"YES" : @"NO")); 
      return toBeReturned;
   }
   
   
   std::string OpenALSound::getError()
   {
      //LOG_SOUND("OpenALSound getError()"); 
      return mError;
   }
   
   
   void OpenALSound::close()
   {
      //LOG_SOUND("OpenALSound close() doing nothing"); 
   }
   
   
   SoundChannel *OpenALSound::openChannel(double startTime, int loops, const SoundTransform &inTransform)
   {
      //LOG_SOUND("OpenALSound openChannel()"); 
      return new OpenALChannel(this, mBufferID, startTime, loops, inTransform);
   }
   
   
   #ifndef IPHONE
   Sound *Sound::Create(const std::string &inFilename,bool inForceMusic)
   {
      //Always check if openal is intitialized
      if (!OpenALInit())
         return 0;
      
      //Return a reference
      #ifdef ANDROID
      ByteArray bytes = AndroidGetAssetBytes(inFilename.c_str());
      return new OpenALSound((float*)bytes.Bytes(), bytes.Size());
      #else
      return new OpenALSound(inFilename);
      #endif
   }
   
   
   Sound *Sound::Create(float *inData, int len, bool inForceMusic)
   {
      //Always check if openal is intitialized
      if (!OpenALInit())
         return 0;

      //Return a reference
      return new OpenALSound(inData, len);
   }
   #endif
   
   
   void Sound::Suspend()
   {
      //Always check if openal is initialized
      if (!OpenALInit())
         return;
      
      OpenALChannel* channel = 0;
      for (int i = 0; i < sgOpenChannels.size(); i++)
      {
         channel = (OpenALChannel*)(sgOpenChannels[i]);
         if (channel)
         {
            channel->pause();
         }
      }
      
      alcMakeContextCurrent(0);
      alcSuspendContext(sgContext);
   }
   
   
   void Sound::Resume()
   {
      //Always check if openal is initialized
      if (!OpenALInit())
         return;
      
      alcMakeContextCurrent(sgContext);
      alcProcessContext(sgContext);
      
      OpenALChannel* channel = 0;
      for (int i = 0; i < sgOpenChannels.size(); i++)
      {
         channel = (OpenALChannel*)(sgOpenChannels[i]);
         if (channel)
         {
            channel->resume();
         }
      }
   }
   
} // end namespace nme
