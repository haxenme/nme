#include "Audio.h"
#include <Sound.h>
#include <Display.h>
#include <SDL.h>
#include <SDL_mixer.h>
#include <Sound.h>
#include <hx/Thread.h>



namespace nme
{

SDLAudioState gSDLAudioState = sdaNotInit;

class SDLSoundChannel;

bool sChannelsInit = false;
enum { sMaxChannels = 8 };

bool sUsedChannel[sMaxChannels];
bool sDoneChannel[sMaxChannels];
void *sUsedMusic = 0;
bool sDoneMusic = false;
enum { STEREO_SAMPLES = 2 };

unsigned int  sSoundPos = 0;
double        sMusicT0 = 0;
double        sLastMusicUpdate = 0;
double        sMusicFrequency = 44100;
bool          sSoundPaused = false;

void onChannelDone(int inChannel)
{
   if (sUsedChannel[inChannel])
      sDoneChannel[inChannel] = true;
}

void onMusicDone()
{
   if (sUsedMusic)
      sDoneMusic = true;
}

#ifdef EMSCRIPTEN
namespace {
void Mix_QuerySpec(int *frequency, Uint16 *format, int *channels)
{
   *frequency = 44100;
   *format = 32784;
   *channels = 2;
}
}
#endif

/*
extern "C" void music_mixer(void *udata, Uint8 *stream, int len);
void onMusic(void *udata, Uint8 *stream, int len)
{
   music_mixer(Mix_GetMusicHookData(), stream, len);
}
*/

void  onPostMix(void *udata, Uint8 *stream, int len)
{
   sSoundPos += len / sizeof(short) / STEREO_SAMPLES ;
   sLastMusicUpdate = GetTimeStamp();
   if (!sMusicT0)
      sMusicT0 = sLastMusicUpdate;
}

int getMixerSamplesSince(int inTime0)
{
   double now = GetTimeStamp();
   if (now>sLastMusicUpdate+0.25)
      return sSoundPos;

   return (sSoundPos-inTime0) + (int)( (now - sLastMusicUpdate)*sMusicFrequency );
}

double getMixerTicks()
{
   double delta = GetTimeStamp()-sLastMusicUpdate;
   if (delta>0.25)
      delta = 0;

   return (sSoundPos)*1000.0/sMusicFrequency + delta*1000.0;

}


static bool Init()
{
   if (gSDLAudioState==sdaNotInit)
   {
      ELOG("Please init Stage before creating sound.");
      return false;
   }
   printf("SDL Audio is open: %d\n", gSDLAudioState==sdaOpen);
   if (gSDLAudioState!=sdaOpen)
     return false;


   if (!sChannelsInit)
   {
      sChannelsInit = true;
      for(int i=0;i<sMaxChannels;i++)
      {
         sUsedChannel[i] = false;
         sDoneChannel[i] = false;
      }
      Mix_ChannelFinished(onChannelDone);
      Mix_HookMusicFinished(onMusicDone);
      //Mix_HookMusic(onMusic,0);
      #ifndef EMSCRIPTEN
      Mix_SetPostMix(onPostMix,0);
      #endif
   }

   printf("Ok.\n");
   return sChannelsInit;
}

// ---  Using "Mix_Chunk" API ----------------------------------------------------


class SDLSoundChannel : public SoundChannel
{
  enum { BUF_SIZE = (1<<17) };

   int       mFrequency;
   Uint16    mFormat;
   int       mChannels;


   int                mAsyncFrequency;
   SoundDataFormat    mAsyncFormat;
   int                mAsyncChannels;
   int                mAsyncBytesPerSample;

   Object    *mSound;
   Mix_Chunk *mChunk;
   int       mChannel;

   void      *mCallback;
   bool      hasAsyncBuffer;
   bool      isAsyncMode;

   int   startSample;
   int   endSample;
   bool  playing;
   int   loopsPending;


   Mix_Chunk mOffsetChunk;
   Mix_Chunk mDynamicChunk;
   short    *mDynamicBuffer;
   unsigned int  mDynamicFillPos;
   unsigned int  mSoundPos0;
   int       mDynamicDataDue;
   bool      mDynamicRequestPending;
   int       mBufferAheadSamples;


public:
   SDLSoundChannel(Object *inSound, Mix_Chunk *inChunk, double inStartTime, int inLoops,
                  const SoundTransform &inTransform)
   {
      init();
      initSpec();
      mChunk = inChunk;
      mDynamicBuffer = 0;
      mSound = inSound;
      mSound->IncRef();
      startSample = endSample = sSoundPos;
      playing = true; 
      loopsPending = 0;

      mChannel = -1;

      bool valid = false;

      mOffsetChunk.alen = 0;
      if (mFrequency && mChunk && mChunk->alen)
      {
         valid = true;
         mOffsetChunk = *mChunk;
         mOffsetChunk.allocated = 0;
         int startBytes = (int)(inStartTime*0.001*mFrequency*sizeof(short)*STEREO_SAMPLES) & ~3;
         int startLoops = startBytes / mChunk->alen;
         if (inLoops>=0)
         {
            inLoops-=startLoops; 
            if (inLoops<0)
               valid = false;
         }
         startBytes = startBytes % mChunk->alen;
         if (valid)
         {
            startSample -= startBytes/(sizeof(short)*STEREO_SAMPLES);
            endSample = startSample;
            mOffsetChunk.alen -= startBytes;
            mOffsetChunk.abuf += startBytes;
            if (startBytes)
            {
               loopsPending = inLoops;
               inLoops = 0;
            }
         }
      }



      // Allocate myself a channel
      if (valid)
      {
         allocChannel();
      }


      if (mChannel<0 || Mix_PlayChannel( mChannel , &mOffsetChunk, inLoops<0 ? -1 : inLoops==0 ? 0 : inLoops-1 )<0)
      {
         onChannelDone(mChannel);
      }
      else
      {
         setTransform(inTransform);
     }
   }


   SDLSoundChannel(const ByteArray &inBytes, const SoundTransform &inTransform)
   {
      init();
      initSpec();
      mChunk = 0;
      mDynamicBuffer = new short[BUF_SIZE * STEREO_SAMPLES];
      memset(mDynamicBuffer,0,BUF_SIZE*sizeof(short));
      mSound = 0;
      mChannel = -1;
      mDynamicChunk.allocated = 0;
      mDynamicChunk.abuf = (Uint8 *)mDynamicBuffer;
      mDynamicChunk.alen = BUF_SIZE * sizeof(short) * STEREO_SAMPLES; // bytes
      mDynamicChunk.volume = MIX_MAX_VOLUME;
      mDynamicFillPos = 0;
      mSoundPos0 = 0;
      mDynamicDataDue = 0;
      loopsPending = 0;

      mBufferAheadSamples = 0;//mFrequency / 20; // 50ms buffer

      // Allocate myself a channel
      allocChannel();

      if (mChannel>=0)
      {
         FillBuffer(inBytes,true);
         // Just once ...
         if (mDynamicFillPos<1024)
         {
            mDynamicRequestPending = true;
            mDynamicChunk.alen = mDynamicFillPos * sizeof(short) * STEREO_SAMPLES;
            if (Mix_PlayChannel( mChannel , &mDynamicChunk,  0 ))
              onChannelDone(mChannel);
         }
         else
         {
            mDynamicRequestPending = false;
            // TODO: Lock?
            if (Mix_PlayChannel( mChannel , &mDynamicChunk,  -1 )<0)
               onChannelDone(mChannel);
         }
         if (!sDoneChannel[mChannel])
         {
            mSoundPos0 = getMixerSamplesSince(0);

            Mix_Volume( mChannel, inTransform.volume*MIX_MAX_VOLUME );
         }
      }
   }

   // Async channel
   SDLSoundChannel( SoundDataFormat inDataFormat,bool inIsStereo, int inRate, void *inCallback)
   {
      init();
      initSpec();
      isAsyncMode = true;
      mAsyncFrequency = inRate;
      mAsyncChannels = inIsStereo ? 2 : 1;
      mAsyncFormat = inDataFormat;

      mDynamicBuffer = new short[BUF_SIZE * STEREO_SAMPLES];
      memset(mDynamicBuffer,0,BUF_SIZE*sizeof(short));
      mSound = 0;
      mChannel = -1;
      mDynamicChunk.allocated = 0;
      mDynamicChunk.abuf = (Uint8 *)mDynamicBuffer;
      mDynamicChunk.alen = BUF_SIZE * sizeof(short) * STEREO_SAMPLES; // bytes
      mDynamicChunk.volume = MIX_MAX_VOLUME;
      mDynamicFillPos = 0;
      mSoundPos0 = 0;
      mDynamicDataDue = 0;
      loopsPending = 0;

      mAsyncBytesPerSample = mAsyncChannels * (mAsyncFormat==sdfByte ? 1 : mAsyncFormat==sdfShort ? 2 : 4);

      allocChannel();

      // Wait for data
   }


   void allocChannel()
   {
      // Allocate myself a channel
      for(int i=0;i<sMaxChannels;i++)
         if (!sUsedChannel[i])
         {
            IncRef();
            sDoneChannel[i] = false;
            sUsedChannel[i] = true;
            mChannel = i;
            break;
         }
   }

   void init()
   {
      mSound = 0;
      mChunk = 0;
      mChannel = -1;
      mCallback = 0;

      startSample = 0;
      endSample = 0;
      playing = false;
      loopsPending = 0;

      mDynamicBuffer = 0;
      mDynamicFillPos = 0;
      mSoundPos0 = 0;
      mDynamicDataDue = 0;
      mDynamicRequestPending = 0;
      mFrequency = 0;
      mFormat = 0;
      mChannels = 0;
      mBufferAheadSamples = 0;

      mAsyncFrequency = 0;
      mAsyncFormat = sdfShort;
      mAsyncChannels = 0;


      hasAsyncBuffer = false;
      isAsyncMode = false;
   }


   void initSpec()
   {
      Mix_QuerySpec(&mFrequency, &mFormat, &mChannels);
      if (mFrequency!=44100)
         ELOG("Warning - Frequency mismatch %d",mFrequency);
      if (mFormat!=32784)
         ELOG("Warning - Format mismatch    %d",mFormat);
      if (mChannels!=2)
         ELOG("Warning - channe mismatch    %d",mChannels);

      if (sMusicFrequency==0)
         sMusicFrequency = mFrequency;
   }

   void setTransform(const SoundTransform &inTransform) 
   {
      if (mChannel>=0)
      {
         Mix_Volume( mChannel, inTransform.volume*MIX_MAX_VOLUME );

         int left = (1-inTransform.pan)*255;
         if (left<0) left = 0;
         if (left>255) left = 255;
   
         int right = (inTransform.pan + 1)*255;
         if (right<0) right = 0;
         if (right>255) right = 255;

         Mix_SetPanning( mChannel, left, right );
      }
   }

   void FillBuffer(const ByteArray &inBytes,bool inFirst)
   {
      int time_samples = inBytes.Size()/sizeof(float)/STEREO_SAMPLES;
      const float *buffer = (const float *)inBytes.Bytes();
      enum { MASK = BUF_SIZE - 1 };

      for(int i=0;i<time_samples;i++)
      {
         int mono_pos =  (i+mDynamicFillPos) & MASK;
         mDynamicBuffer[ mono_pos<<1 ] = *buffer++ * ((1<<15)-1);
         mDynamicBuffer[ (mono_pos<<1) + 1 ] = *buffer++ * ((1<<15)-1);
      }

      int soundTime = getMixerSamplesSince(mSoundPos0);

      if (mDynamicFillPos<soundTime && !inFirst)
         ELOG("Too slow - FillBuffer %d / %d)", mDynamicFillPos, soundTime );
      mDynamicFillPos += time_samples;
      if (time_samples<1024 && !mDynamicRequestPending)
      {
         mDynamicRequestPending = true;
         for(int i=0;i<2048;i++)
         {
            int mono_pos =  (i+mDynamicFillPos) & MASK;
            mDynamicBuffer[ mono_pos<<1 ] = 0;
            mDynamicBuffer[ (mono_pos<<1) + 1 ] = 0;
         }

         #ifndef EMSCRIPTEN
         int samples_left = (int)mDynamicFillPos - (int)(soundTime);
         int ticks_left = samples_left*1000/44100;
         //printf("Expire in %d (%d)\n", samples_left, ticks_left );
         Mix_ExpireChannel(mChannel, ticks_left>0 ? ticks_left : 1 );
         #endif
      }
   }

   inline void SetDest(short &outDest, const short &inSrc) { outDest = inSrc; }
   inline void SetDest(short &outDest, const float &inSrc) { outDest = inSrc*32575.0f; }
   inline void SetDest(short &outDest, const unsigned char &inSrc) { outDest = (inSrc<<8)-(255<<7); }

   template<bool STEREO,int SCALE, typename SAMPLE>
   void TTAddAsyncSamplesType(const SAMPLE *inBuffer, int inSamples)
   {
      short *dest = mDynamicBuffer + (mDynamicFillPos<<1);
      for(int i=0;i<inSamples;i++)
      {
         SetDest(*dest++,*inBuffer++);
         if (STEREO)
            SetDest(*dest++,*inBuffer++);
         else
            { dest[1] = dest[0]; dest++; }

         // TODO - better scaling
         if (SCALE>1)
         {
            dest[0] = dest[-2];
            dest[1] = dest[-1];
            dest+=2;
            if (SCALE>2)
            {
               dest[0] = dest[-2];
               dest[1] = dest[-1];
               dest[2] = dest[-2];
               dest[3] = dest[-1];
               dest+=4;
            }
         }
      }
   }

   template<bool STEREO,int SCALE>
   void TTAddAsyncSamples(const unsigned char *inBuffer, int inSamples)
   {
      if (mAsyncFormat==sdfShort)
         TTAddAsyncSamplesType<STEREO,SCALE>( (const short *)inBuffer, inSamples);
      else if (mAsyncFormat==sdfByte)
         TTAddAsyncSamplesType<STEREO,SCALE>( (const unsigned char *)inBuffer, inSamples);
      else
         TTAddAsyncSamplesType<STEREO,SCALE>( (float *)inBuffer, inSamples);
   }

   template<bool STEREO>
   void TAddAsyncSamples(const unsigned char *inBuffer, int inSamples)
   {
      if (mAsyncFrequency==11025)
         TTAddAsyncSamples<STEREO,4>(inBuffer,inSamples);
      else if (mAsyncFrequency==22050)
         TTAddAsyncSamples<STEREO,2>(inBuffer,inSamples);
      else if (mAsyncFrequency==44100)
         TTAddAsyncSamples<STEREO,1>(inBuffer,inSamples);
   }

   void addAsyncSamples(const unsigned char *inBuffer, int inSamples)
   {
      if (mChannels==2)
         TAddAsyncSamples<true>(inBuffer, inSamples);
      else
         TAddAsyncSamples<false>(inBuffer, inSamples);

      mDynamicFillPos = (mDynamicFillPos + inSamples) & (BUF_SIZE-1);
   }


   void FillBufferAsync(const ByteArray &inBytes)
   {
      int timeSamples = inBytes.Size()/mAsyncBytesPerSample;
      bool last = timeSamples<1024;
      const unsigned char *buffer = (const unsigned char *)inBytes.Bytes();

      int timesRemaining = BUF_SIZE-mDynamicFillPos;

      int add = timesRemaining < timeSamples ? timesRemaining : timeSamples;
      // Handle circular buffer
      addAsyncSamples( buffer, add);
      timeSamples -= add;
      if (timeSamples)
         addAsyncSamples( buffer + add*mAsyncBytesPerSample, timeSamples);
   }
 
   ~SDLSoundChannel()
   {
      delete [] mDynamicBuffer;

      if (mCallback)
         DestroyAsyncCallback(mCallback);

      if (mSound)
         mSound->DecRef();
   }

   void CheckDone()
   {
      if (mChannel>=0 && sDoneChannel[mChannel])
      {
         if (loopsPending!=0 && mChunk)
         {
            mOffsetChunk.alen = mChunk->alen;
            mOffsetChunk.abuf = mChunk->abuf;
            if (Mix_PlayChannel( mChannel , &mOffsetChunk, loopsPending<0 ? -1 : loopsPending-1 )==0)
            {
               startSample = endSample = sSoundPos;
               loopsPending = 0;
               sDoneChannel[mChannel] = false;
               return;
            }
         }

         sDoneChannel[mChannel] = false;
         int c = mChannel;
         mChannel = -1;
         DecRef();
         sUsedChannel[c] = 0;
         endSample = sSoundPos;
      }
   }

   bool isComplete()
   {
      CheckDone();
      return mChannel < 0;
   }
   double getLeft() { return 1; }
   double getRight() { return 1; }
   double setPosition(const float &inFloat) { return 1; }
   void stop() 
   {
      if (mChannel>=0)
      {
         if (gSDLAudioState==sdaOpen)
            Mix_HaltChannel(mChannel);
         sDoneChannel[mChannel] = true;
         loopsPending = 0;
      }
      //CheckDone();
   }

   double getPosition()
   {
      if (!sMusicFrequency || !mChunk || !mChunk->alen)
         return 0.0;

      int samples = mChunk->alen / (sizeof(short)*STEREO_SAMPLES);
      return (playing ? (sSoundPos - startSample) % samples : endSample - startSample)*1000.0/sMusicFrequency;
   }


   double getDataPosition()
   {
      return getMixerSamplesSince(mSoundPos0)*1000.0/mFrequency;
   }
   bool needsData()
   {
      if (!mDynamicBuffer || mDynamicRequestPending || isAsyncMode)
         return false;

      int soundTime = getMixerSamplesSince( mSoundPos0 );
      if (mDynamicDataDue<=soundTime + mBufferAheadSamples)
      {
         mDynamicRequestPending = true;
         return true;
      }

      return false;

   }

   void addData(const ByteArray &inBytes)
   {
      if (isAsyncMode)
      {
         if (mChannel<0)
            return;
         if (!hasAsyncBuffer)
            mSoundPos0 = getMixerSamplesSince(0);
         FillBufferAsync(inBytes);
         if (!hasAsyncBuffer)
         {
            hasAsyncBuffer = true;
            if (Mix_PlayChannel( mChannel , &mDynamicChunk,  0 ))
            {
               onChannelDone(mChannel);
               mChannel = -1;
            }
         }
      }
      else
      {
         mDynamicRequestPending = false;
         int soundTime = getMixerSamplesSince(mSoundPos0);
         mDynamicDataDue = mDynamicFillPos;
         FillBuffer(inBytes,false);
      }
   }


};

SoundChannel *CreateSdlSyncChannel(const ByteArray &inBytes,const SoundTransform &inTransform,
    SoundDataFormat inDataFormat,bool inIsStereo, int inRate) 
{
   if (!Init())
      return 0;
   return new SDLSoundChannel(inBytes,inTransform);
}


SoundChannel *CreateSdlAsyncChannel( SoundDataFormat inDataFormat,bool inIsStereo, int inRate, void *inCallback)
{
   if (!Init())
      return 0;
   return new SDLSoundChannel(inDataFormat, inIsStereo, inRate, inCallback);
}



class SDLSound : public Sound
{
   std::string mError;
   Mix_Chunk *mChunk;
   std::string filename;
   bool        loaded;
   int         frequency;
   Uint16      format;
   int         channels;
   double      duration;
   INmeSoundData *soundData;

public:
   SDLSound(const std::string &inFilename)
   {
      initSound();
      filename = inFilename;
      Mix_QuerySpec(&frequency, &format, &channels);

      if (Init())
         loadChunk();
   }

   SDLSound(const unsigned char *inData, int len)
   {
      initSound();
      if (Init())
      {
         mChunk = Mix_LoadWAV_RW(SDL_RWFromConstMem(inData, len), 1);
         onChunk();
      }
   }

   void initSound()
   {
      IncRef();
      mChunk = 0;
      loaded = false;
      frequency = 0;
      format = 0;
      channels = 0;
      duration = 0.0;
      soundData = 0;
      Mix_QuerySpec(&frequency, &format, &channels);
   }

   ~SDLSound()
   {
      if (mChunk)
         Mix_FreeChunk( mChunk );

      if (soundData)
         soundData->release();
   }

   const char *getEngine() { return "sdl sound"; }

   void setSoundData(INmeSoundData *inData)
   {
      #ifndef EMSCRIPTEN
      // TODO
      soundData = inData;
      Uint8 *data = (Uint8 *)soundData->decodeAll();
      if (data)
      {
         int bytes = soundData->getDecodedByteCount();
         if (soundData->getRate()!=frequency || !soundData->getIsStereo())
         {
            SDL_AudioCVT wavecvt;
            if (SDL_BuildAudioCVT(&wavecvt,
                    format, soundData->getIsStereo() ? 2 : 1, soundData->getRate(),
                    format, channels, frequency) >= 0)
            {
               int samplesize = 2 * sizeof(short);
               int sampleCount = soundData->getChannelSampleCount();

               wavecvt.len = soundData->getDecodedByteCount();
               wavecvt.buf = (Uint8 *)SDL_calloc(1, wavecvt.len*wavecvt.len_mult);
               SDL_memcpy(wavecvt.buf, data, bytes);
               SDL_ConvertAudio(&wavecvt);
               mChunk = Mix_QuickLoad_RAW(wavecvt.buf, wavecvt.len_cvt);
            }
            soundData->release();
            soundData = 0;
         }
         else
         {
            mChunk = Mix_QuickLoad_RAW(data, bytes);
         }
         if (mChunk)
            onChunk();
      }
      #endif
   }

   void loadChunk()
   {
      #ifdef HX_MACOS
      char name[1024];
      GetBundleFilename(filename.c_str(),name,1024);
      #else
      const char *name = filename.c_str();
      #endif

      mChunk = Mix_LoadWAV(name);
      //printf("Loaded wav : %s = %p\n", name, mChunk);

      #ifdef HX_MACOS
      if (!mChunk)
      {
         INmeSoundData *data = INmeSoundData::createAvDecoded(name);
         if (data)
            setSoundData(data);
      }
      #endif

      if (!mChunk)
      {
         ByteArray resource(filename.c_str());
         if (resource.Ok())
         {
            int n = resource.Size();
            if (n>0)
            {
               #ifndef NME_SDL12
               mChunk = Mix_LoadWAV_RW(SDL_RWFromConstMem(resource.Bytes(),n),false);
               #else
               mChunk = Mix_LoadWAV_RW(SDL_RWFromConstMem(resource.Bytes(),2));
               #endif
            }
            if (!mChunk)
            {
               INmeSoundData *data = INmeSoundData::create(resource.Bytes(),n,SoundForceDecode);
               if (data)
               {
                  setSoundData(data);
               }
           }
         }
      }

      onChunk();
   }

   void onChunk()
   {
      loaded = true;
      if (mChunk)
      {
         int bytes = mChunk->alen;
         if (bytes && frequency && channels)
            duration = (double)bytes/ (frequency*channels*sizeof(short) );
      }
      else
      {
         mError = SDL_GetError();
         // ELOG("Error %s (%s)", mError.c_str(), name );
      }
   }
  
   double getLength()
   {
     return duration*1000.0;
     //#if defined(DYNAMIC_SDL) || defined(WEBOS)
   }

   // Will return with one ref...
   SoundChannel *openChannel(double startTime, int loops, const SoundTransform &inTransform)
   {
      if (!loaded)
         loadChunk();
      if (!mChunk)
         return 0;
      return new SDLSoundChannel(this,mChunk,startTime, loops,inTransform);
   }
   int getBytesLoaded() { return mChunk ? mChunk->alen : 0; }
   int getBytesTotal() { return mChunk ? mChunk->alen : 0; }
   bool ok() { return mChunk; }
   std::string getError() { return mError; }
};

// ---  Using "Mix_Music" API ----------------------------------------------------


class SDLMusicChannel : public SoundChannel
{
public:
   bool      mPlaying;
   Object    *mSound;
   int       mStartTime;
   double    mDuration;
   int       mStoppedLength;
   Mix_Music *mMusic;

   SDLMusicChannel(Sound *inSound, Mix_Music *inMusic, double inStartTime, int inLoops,
                  const SoundTransform &inTransform)
   {
      mMusic = inMusic;
      mSound = inSound;
      mSound->IncRef();
      mDuration = inSound->getLength();

      mPlaying = false;
      if (mMusic)
      {
         mPlaying = true;
         sUsedMusic = this;
         sDoneMusic = false;
         mStartTime = getMixerTicks();
         mStoppedLength = 0;
         IncRef();

         int iStartTime = inStartTime;
         // Seems odd...
         //int sdlLoops = inLoops<0 ? -1 : inLoops==0 ? 1 : inLoops;
         int sdlLoops = inLoops<0 ? -1 : inLoops==0 ? 0 : inLoops-1;
         //int sdlLoops = inLoops;
         if (Mix_PlayMusic( mMusic, sdlLoops )<0)
         {
            onMusicDone();
         }
         else
         {
            Mix_VolumeMusic( inTransform.volume*MIX_MAX_VOLUME );
            if (iStartTime > 0)
            {
               // Should be 'almost' at start
               //Mix_RewindMusic();
               #ifndef EMSCRIPTEN
               Mix_SetMusicPosition(iStartTime*0.001); 
               #else
               iStartTime = 0;
               #endif
               mStartTime = getMixerTicks() - iStartTime;
            }
            // Mix_SetPanning not available for music
         }
      }
   }
   ~SDLMusicChannel()
   {
      mSound->DecRef();
   }

   void CheckDone()
   {
      if (mPlaying && (sDoneMusic || (sUsedMusic!=this)) )
      {
         mStoppedLength = getMixerTicks() - mStartTime;
         mPlaying = false;
         if (sUsedMusic == this)
         {
            sUsedMusic = 0;
            sDoneMusic = false;
         }
         DecRef();
      }
   }

   bool isComplete()
   {
      CheckDone();
      return !mPlaying;
   }
   double getLeft() { return 1; }
   double getRight() { return 1; }
   double getPosition()
   {
      if (!mPlaying)
         return mStoppedLength;
      while(true)
      {
         double pos = getMixerTicks() - mStartTime;
         if (mDuration>0.01 && pos>mDuration)
            mStartTime += mDuration;
         else
            return pos;
      }
      return 0;
   }
   double setPosition(const float &inFloat) { return 1; }

   void stop() 
   {
      if (mMusic)
      {
         Mix_HaltMusic();
         if (sUsedMusic == this)
            sDoneMusic = true;
      }
   }
   void setTransform(const SoundTransform &inTransform) 
   {
      if (mMusic && inTransform.volume>=0)
         Mix_VolumeMusic( inTransform.volume*MIX_MAX_VOLUME );
   }

};


class SDLMusic : public Sound
{
   bool loaded;
   std::string filename;
   std::vector<unsigned char> reso;
   double duration;

public:
   SDLMusic(const std::string &inFilename)
   {
      filename = inFilename;
      loaded = false;
      mMusic = 0;
      duration = 0;

      IncRef();
      if (gSDLAudioState!=sdaNotInit)
      {
         if (Init())
            loadMusic();
         else
            DecRef();
      }
   }

  const char *getEngine() { return "sdl music"; }


   void loadMusic()
   {
      loaded = true;
      #ifdef HX_MACOS
      char name[1024];
      GetBundleFilename(filename.c_str(),name,1024);
      #else
      const char *name = filename.c_str();
      #endif

      mMusic = Mix_LoadMUS(name);
      if (mMusic)
      {
         INmeSoundData *stream = INmeSoundData::create(name,SoundJustInfo);
         if (stream)
         {
            duration = stream->getDuration() * 1000.0;
            stream->release();
         }
      }
      else
      {
         ByteArray resource(filename.c_str());
         if (resource.Ok())
         {
            int n = resource.Size();
            if (n>0)
            {
               reso.resize(n);
               memcpy(&reso[0], resource.Bytes(), n);
               #ifdef NME_SDL2
               mMusic = Mix_LoadMUS_RW(SDL_RWFromConstMem(&reso[0], reso.size()),false);
               #else
               mMusic = Mix_LoadMUS_RW(SDL_RWFromConstMem(&reso[0], reso.size()));
               #endif

               if (mMusic)
               {
                  INmeSoundData *stream = INmeSoundData::create(&reso[0], reso.size(),SoundJustInfo);
                  if (stream)
                  {
                     duration = stream->getDuration() * 1000.0;
                     stream->release();
                  }
                  else
                  {
                     ELOG("Could not determine music length - assume large");
                     duration = 600000000.0;
                  }
               }
            }
         }
      }


      if (!mMusic)
      {
         mError = SDL_GetError();
         //ELOG("Error in music %s (%s)", mError.c_str(), name );
      }
   }
   
   SDLMusic(const unsigned char *inData, int len)
   {
      IncRef();
      
      if(!Init()) {
         mMusic = 0;
         return;
      }
      
      loaded = true;
      
      reso.resize(len);
      memcpy(&reso[0], inData, len);

      #ifdef NME_SDL2
      mMusic = Mix_LoadMUS_RW(SDL_RWFromConstMem(&reso[0], len),false);
      #else
      mMusic = Mix_LoadMUS_RW(SDL_RWFromConstMem(&reso[0], len));
      #endif
      if ( mMusic == NULL )
      {
         mError = SDL_GetError();
         ELOG("Error in music with len (%d)", len );
      }
   }
   ~SDLMusic()
   {
      if (mMusic)
      {
         Mix_FreeMusic( mMusic );
      }
   }
   double getLength()
   {
      return duration;
   }
   // Will return with one ref...
   SoundChannel *openChannel(double startTime, int loops, const SoundTransform &inTransform)
   {
      if (!loaded)
         loadMusic();

      if (!mMusic)
         return 0;
      return new SDLMusicChannel(this,mMusic,startTime, loops,inTransform);
   }
   int getBytesLoaded() { return mMusic ? 100 : 0; }
   int getBytesTotal() { return mMusic ? 100 : 0; }
   bool ok() { return mMusic; }
   std::string getError() { return mError; }


   std::string mError;
   Mix_Music *mMusic;
};

// --- External Interface -----------------------------------------------------------


void SuspendSdlSound()
{
   if (gSDLAudioState!=sdaOpen)
     return;

   sSoundPaused = true;
   SDL_PauseAudio(true);
}

void ResumeSdlSound()
{
   if (gSDLAudioState!=sdaOpen)
     return;

   sSoundPaused = false;
   SDL_PauseAudio(false);
}

Sound *CreateSdlSound(const std::string &inFilename,bool inForceMusic)
{
   Sound *sound = inForceMusic ? 0 :  new SDLSound(inFilename);

   if (!sound || !sound->ok())
   {
      if (sound) sound->DecRef();
      sound = new SDLMusic(inFilename);
   }
   #if defined(HX_WINDOWS) || defined(HX_MACOS)
   // Try as sound after all...
   if (inForceMusic && (!sound || !sound->ok()))
   {
      if (sound) sound->DecRef();
      sound = new SDLSound(inFilename);
   }
   #endif
   return sound;
}

Sound *CreateSdlSound(const unsigned char *inData, int len, bool inForceMusic)
{
   Sound *sound = inForceMusic ? 0 : new SDLSound(inData, len);
   if (!sound || !sound->ok())
   {
      if (sound) sound->DecRef();
      sound = new SDLMusic(inData, len);
   }
   #ifdef HX_WINDOWS
   // Try as sound after all...
   if (inForceMusic && (!sound || !sound->ok()))
   {
      if (sound) sound->DecRef();
      sound = new SDLSound(inData, len);
   }
   #endif
   return sound;
}


}
