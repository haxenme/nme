#include "Audio.h"
#include <Sound.h>
#include <Display.h>
#include <SDL.h>
#include <SDL_mixer.h>
#include <Sound.h>
#include <hx/Thread.h>

#ifndef NME_SDL3
 #define SDL_IOFromConstMem(data, len) SDL_RWFromConstMem(data, len)
#else
 #define Mix_LoadWAV_RW Mix_LoadWAV_IO
 #define Mix_LoadMUS_RW Mix_LoadMUS_IO
#endif


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
#ifdef NME_SDL3
double        sMusicFrequency = 0.0;
#else
double        sMusicFrequency = 44100;
#endif
int           sMusicSampleSize = sizeof(short);
int           sMusicChannels = STEREO_SAMPLES;
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
void Mix_QuerySpec(int *frequency, SDL_AudioFormat *format, int *channels)
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
   sSoundPos += len / sMusicSampleSize / sMusicChannels ;
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
   //printf("SDL Audio is open: %d\n", gSDLAudioState==sdaOpen);
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

   //printf("Ok.\n");
   return sChannelsInit;
}


#ifndef NME_SDL3 // {

// ---  Using "Mix_Chunk" API ----------------------------------------------------
// Mixer
class SDLSoundChannel : public SoundChannel
{
  enum { BUF_SIZE = (1<<17) };

   int             mFrequency;
   SDL_AudioFormat mFormat;
   int             mChannels;


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
   // Mixer
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


   // Sync channel
   // Mixer
   SDLSoundChannel(const ByteArray &inBytes, const SoundTransform &inTransform,  SoundDataFormat inDataFormat,bool inIsStereo, int inRate)
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
   // Mixer
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


   // Mixer
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

   // Mixer
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
      mFormat = (SDL_AudioFormat)0;
      mChannels = 0;
      mBufferAheadSamples = 0;

      mAsyncFrequency = 0;
      mAsyncFormat = sdfShort;
      mAsyncChannels = 0;


      hasAsyncBuffer = false;
      isAsyncMode = false;
   }


   // Mixer
   void initSpec()
   {
      Mix_QuerySpec(&mFrequency, &mFormat, &mChannels);

      if (mFrequency!=44100)
         ELOG("Warning - Frequency mismatch %d",mFrequency);
      if (mFormat!=32784)
         ELOG("Warning - Format mismatch    %d",(int)mFormat);
      if (mChannels!=2)
         ELOG("Warning - channel mismatch    %d",mChannels);

      if (sMusicFrequency==0)
         sMusicFrequency = mFrequency;
   }

   // Mixer
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

   // Mixer
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


   // Mixer
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
 
   // Mixer
   ~SDLSoundChannel()
   {
      delete [] mDynamicBuffer;

      if (mCallback)
         DestroyAsyncCallback(mCallback);

      if (mSound)
         mSound->DecRef();
   }

   // Mixer
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

   // Mixer
   bool isComplete()
   {
      CheckDone();
      return mChannel < 0;
   }
   double getLeft() { return 1; }
   double getRight() { return 1; }
   double setPosition(const float &inFloat) { return 1; }
   // Mixer
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

   // Mixer
   double getPosition()
   {
      if (!sMusicFrequency || !mChunk || !mChunk->alen)
         return 0.0;

      int samples = mChunk->alen / (sizeof(short)*STEREO_SAMPLES);
      return (playing ? (sSoundPos - startSample) % samples : endSample - startSample)*1000.0/sMusicFrequency;
   }


   // Mixer
   double getDataPosition()
   {
      return getMixerSamplesSince(mSoundPos0)*1000.0/mFrequency;
   }
   // Mixer
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

   // Mixer
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




#else // }  NME_SDL3  {
// ---  Using "SDL_AudioStream" API ----------------------------------------------------

static SDL_AudioDeviceID sSdlSoundDevice = 0;
static double sSdlSoundDeviceTime = 0.0;
static int sSdlActiveSoundCount;

static void SDLCALL audioCounter(void *userdata, const SDL_AudioSpec *spec, float *buffer, int buflen)
{
   int frames = buflen/(sizeof(float)*spec->channels);
   sSdlSoundDeviceTime += (double)frames/spec->freq;
   //printf(" t=%.3f\n", sSdlSoundDeviceTime);
}

enum ChannelMode
{
   cmChunk,
   cmAsyncCallback,
   cmCallback,
   cmDrain,
   cmDone,
};

class SDLSoundChannel : public SoundChannel
{
   enum { BUF_SIZE = (1<<17) };
 
   SDL_AudioStream *stream;
   SDL_AudioSpec   spec;

   Object    *mSound;
   Mix_Chunk *mChunk;

   ChannelMode channelMode;

   double startPosition;
   int   loopsPending;
   int   inputSampleSize;
   bool  active;
   double audioTime0;


public:
   // AudioStream - inChunk should be SDL_mixer format
   SDLSoundChannel(Object *inSound, Mix_Chunk *inChunk, double inStartTime, int inLoops,
                  const SoundTransform &inTransform)
   {
      init(cmChunk);
      Mix_QuerySpec(&spec.freq, &spec.format, &spec.channels);
      setSampleSize();
      mChunk = inChunk;

      mSound = inSound;
      mSound->IncRef();
      loopsPending = 0;

      bool valid = false;

      //printf("AudioStream %d x %d loops=%d\n", spec.freq, mChunk ? mChunk->alen : 0, inLoops);
      if (spec.freq && mChunk && mChunk->alen)
      {
         valid = true;
         startPosition = inStartTime*0.001;
         int startBytes = (int)(startPosition*spec.freq) * inputSampleSize;
         int startLoops = startBytes / mChunk->alen;
         if (inLoops>=0)
         {
            inLoops-=startLoops; 
            if (inLoops<0)
            {
               valid = false;
               inLoops = 0;
            }
         }
         startBytes = startBytes % mChunk->alen;
         if (valid)
         {
            loopsPending = inLoops > 0 ? inLoops-1 : inLoops;
            stream = SDL_CreateAudioStream(&spec, &spec);
            //printf(" created stream %p\n", stream);

            bool ok = SDL_PutAudioStreamData(stream, mChunk->abuf + startBytes, mChunk->alen - startBytes );

            if (ok)
               activate(&inTransform);
            else
               closeStream();
         }
      }
      //printf(" -> channel %d\n", mChannel);

   }

   void activate(const SoundTransform *inTransform=nullptr)
   {
      active = true;
      sSdlActiveSoundCount++;
      if (!sSdlSoundDevice)
      {
         sSdlSoundDevice = SDL_OpenAudioDevice(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, nullptr);
         sSdlSoundDeviceTime = 0.0;
         SDL_SetAudioPostmixCallback( sSdlSoundDevice, audioCounter, nullptr);
         //printf("Opened sdl sound device %d\n", (int)sSdlSoundDevice);
      }

      //printf("  added bytes %d-%d -> ok=%d\n", mChunk->alen,startBytes,ok);
      if (!SDL_BindAudioStream(sSdlSoundDevice, stream ))
      {
         //printf(" could not SDL_BindAudioStream %s\n", SDL_GetError());
         closeStream();
      }
      else
      {
         if (inTransform)
            setTransform(*inTransform);
      }
   }

   static int getSampleSize(SDL_AudioSpec *s)
   {
      switch(s->format)
      {
         case SDL_AUDIO_U8: return s->channels;
         case SDL_AUDIO_S16: return s->channels*2;
         case SDL_AUDIO_F32: return s->channels*4;
         default: ;
      }
      return 0;
   }

   void setSampleSize()
   {
      inputSampleSize = getSampleSize(&spec);
   }


   void setSpec( SoundDataFormat inDataFormat,bool inIsStereo, int inRate )
   {
      spec.freq = inRate;
      spec.format = inDataFormat == sdfByte ? SDL_AUDIO_U8 : inDataFormat==sdfShort ? SDL_AUDIO_S16 : SDL_AUDIO_F32;
      spec.channels = inIsStereo ? 2 : 1;
      setSampleSize();
   }

   // Sync channel
   // AudioStream
   SDLSoundChannel(const ByteArray &inBytes, const SoundTransform &inTransform,  SoundDataFormat inDataFormat,bool inIsStereo, int inRate)
   {
      init(cmCallback);
      mChunk = 0;
      mSound = 0;

      //printf(" AudioStream sync channel %d\n", mChannel);
      setSpec( inDataFormat,inIsStereo,inRate );
      stream = SDL_CreateAudioStream(&spec, &spec);

      SDL_PutAudioStreamData(stream, inBytes.Bytes(), inBytes.Size());
      activate(&inTransform);
   }

   // Async channel
   // AudioStream - async
   SDLSoundChannel( SoundDataFormat inDataFormat,bool inIsStereo, int inRate, void *inCallback)
   {
      init(cmAsyncCallback);

      //printf(" AudioStream async channel %d\n", mChannel);
      setSpec( inDataFormat,inIsStereo,inRate );
      stream = SDL_CreateAudioStream(&spec, &spec);
      activate();
   }

   // AudioStream
   ~SDLSoundChannel()
   {
      if (mSound)
         mSound->DecRef();

      closeStream();
   }

   void closeStream()
   {
      //printf("closeStream %d %p\n", mChannel, stream);
      if (stream)
      {
         SDL_DestroyAudioStream(stream);
         stream = nullptr;

         if (active)
         {
            active = false;
            sSdlActiveSoundCount--;
            if (sSdlSoundDevice && !sSdlActiveSoundCount)
            {
               SDL_CloseAudioDevice( sSdlSoundDevice );
               sSdlSoundDevice = 0;
               sSdlSoundDeviceTime = 0.0;
            }
         }
      }
   }


   // AudioStream
   void init(ChannelMode inMode)
   {
      channelMode = inMode;
      active = false;
      stream = nullptr;
      mSound = nullptr;
      mChunk = nullptr;
      loopsPending = 0;
      inputSampleSize = 0;
      startPosition = 0.0;
      audioTime0 = sSdlSoundDeviceTime;
   }


   // AudioStream
   void setTransform(const SoundTransform &inTransform) 
   {
      if (stream)
         SDL_SetAudioStreamGain(stream, inTransform.volume);
   }


   // AudioStream
   bool CheckDone()
   {
      if (channelMode==cmCallback)
         return false;

      if (channelMode!=cmDone)
      {
         bool done = !stream || SDL_GetAudioStreamAvailable(stream)==0;
         if (done && channelMode==cmAsyncCallback)
         {
            printf("Todo - asyncCallback\n");
         }
         if (done && loopsPending!=0 && mChunk && stream)
         {
            //printf("loopsPending -> %d\n", loopsPending);
            if (SDL_PutAudioStreamData(stream, mChunk->abuf, mChunk->alen ))
            {
               if (loopsPending>0)
                  loopsPending--;
               return false;
            }
         }

         if (done)
            channelMode = cmDone;
      }

      return channelMode==cmDone;
   }

   // AudioStream
   bool isComplete()
   {
      bool complete = CheckDone();
      if (complete)
         closeStream();
      return complete;
   }
   double getLeft() { return 1; }
   double getRight() { return 1; }
   double setPosition(const float &inFloat) { return 1; }
   void stop() 
   {
      //printf("AudioStream stop %d\n", mChannel);
      closeStream();
      //CheckDone();
   }

   // AudioStream
   double getPosition()
   {
      if (!stream || channelMode==cmDone)
         return 0.0;

      return 1000.0 * (startPosition + sSdlSoundDeviceTime - audioTime0);
   }


   double getDataPosition()
   {
      if (!stream || !spec.freq)
         return 0.0;

      return (sSdlSoundDeviceTime - audioTime0) / spec.freq;
   }

   // AudioStream
   bool needsData()
   {
      if (!stream || channelMode!=cmCallback || inputSampleSize<0)
         return false;

      int remaining = SDL_GetAudioStreamAvailable(stream);
      //printf("  remaining: %d\n", remaining);
      if (remaining==0)
         return true;

      SDL_AudioSpec src_spec;
      SDL_AudioSpec dst_spec;
      if (SDL_GetAudioStreamFormat(stream, &src_spec, &dst_spec))
      {
         int size = getSampleSize(&dst_spec);
         if (size>0)
         {
            int frames = remaining/size;
            double seconds = (double)frames/dst_spec.freq;
            //printf("   = %.03f\n", seconds);
            return seconds < 0.050;
         }
      }

      return false;

   }

   // AudioStream
   void addData(const ByteArray &inBytes)
   {
      //printf("AudioStream addData %d %p %d\n", mChannel, stream, inputSampleSize);
      if (channelMode!=cmDone && stream && inputSampleSize)
      {
         if (channelMode==cmCallback)
         {
            int frames = inBytes.Size()/inputSampleSize;
            if (frames<1024)
               channelMode = cmDrain;
         }

         if (!SDL_PutAudioStreamData(stream, inBytes.Bytes(), inBytes.Size() ))
         {
            channelMode = cmDrain;
         }
      }
   }

};


#endif // } end NME_SDL3






SoundChannel *CreateSdlSyncChannel(const ByteArray &inBytes,const SoundTransform &inTransform,
    SoundDataFormat inDataFormat,bool inIsStereo, int inRate) 
{
   if (!Init())
      return 0;
   return new SDLSoundChannel(inBytes,inTransform,inDataFormat, inIsStereo, inRate);
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
   SDL_AudioFormat format;
   int         channels;
   int         sampleSize;
   double      duration;
   INmeSoundData *soundData;

public:
   SDLSound(const std::string &inFilename)
   {
      initSound();
      filename = inFilename;
      sampleSize = sizeof(short);
      Mix_QuerySpec(&frequency, &format, &channels);
      #ifdef NME_SDL3
      switch(format)
      {
         case SDL_AUDIO_U8: sampleSize = 1; break;
         case SDL_AUDIO_S16: sampleSize = 2; break;
         case SDL_AUDIO_F32: sampleSize = 4; break;
         default: ;
      }
      #endif

      if (Init())
         loadChunk();
   }

   SDLSound(const unsigned char *inData, int len)
   {
      initSound();
      if (Init())
      {
         mChunk = Mix_LoadWAV_RW(SDL_IOFromConstMem(inData, len), 1);

         if (!mChunk)
         {
            INmeSoundData *data = INmeSoundData::create(inData,len,SoundForceDecode);
            if (data)
            {
               setSoundData(data);
            }
            #ifdef HX_MACOS
            else
            {
               INmeSoundData *data = INmeSoundData::createAvDecoded(inData,len);
               if (data)
                  setSoundData(data);
            }
            #endif
         }
 
         onChunk();
      }
   }

   void initSound()
   {
      IncRef();
      mChunk = 0;
      loaded = false;
      frequency = 0;
      format = (SDL_AudioFormat)0;
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
            #ifdef NME_SDL3

            Uint8 *dst_data = NULL;
            int dst_len = 0;
            const SDL_AudioSpec src_spec = { format,
                                             soundData->getIsStereo() ? 2 : 1,
                                             soundData->getRate() };
            const SDL_AudioSpec dst_spec = { format, channels, frequency };
            if (!SDL_ConvertAudioSamples(&src_spec, data, soundData->getDecodedByteCount(),
                                &dst_spec, &dst_data, &dst_len))
            {
               printf("Could not convert data?\n");
            }
            else
            {
               mChunk = Mix_QuickLoad_RAW(dst_data, dst_len);
               SDL_free(dst_data);
            }
            #else
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
            #endif

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
               mChunk = Mix_LoadWAV_RW(SDL_IOFromConstMem(resource.Bytes(),n),false);
               #else
               mChunk = Mix_LoadWAV_RW(SDL_IOFromConstMem(resource.Bytes(),2));
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
         {
            duration = (double)bytes/ (frequency*channels*sampleSize );
         }
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

      #ifdef NME_SDL3
      if (!sMusicFrequency)
      {
         SDL_AudioFormat fmt;
         int ch;
         int freq;
         Mix_QuerySpec(&freq, &fmt, &ch);
         sMusicFrequency = freq;
         sMusicChannels = ch;
         switch(fmt)
         {
            case SDL_AUDIO_U8: sMusicSampleSize = 1; break;
            case SDL_AUDIO_S16: sMusicSampleSize = 2; break;
            case SDL_AUDIO_F32: sMusicSampleSize = 4; break;
            default: ;
         }

      }
      #endif

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
         #ifdef NME_SDL3
         if (!Mix_PlayMusic( mMusic, sdlLoops ))
         #else
         if (Mix_PlayMusic( mMusic, sdlLoops )<0)
         #endif
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

   // Music
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
               mMusic = Mix_LoadMUS_RW(SDL_IOFromConstMem(&reso[0], reso.size()),false);
               #else
               mMusic = Mix_LoadMUS_RW(SDL_IOFromConstMem(&reso[0], reso.size()));
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
      mMusic = Mix_LoadMUS_RW(SDL_IOFromConstMem(&reso[0], len),false);
      #else
      mMusic = Mix_LoadMUS_RW(SDL_IOFromConstMem(&reso[0], len));
      #endif


      if ( mMusic == NULL )
      {
         mError = SDL_GetError();
         //ELOG("Error in music with len (%d)", len );
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
   #ifdef NME_SDL3
   if (sSdlSoundDevice)
      SDL_PauseAudioDevice(sSdlSoundDevice);
   #endif

   sSoundPaused = true;
   if (gSDLAudioState!=sdaOpen)
     return;

   #ifdef NME_SDL3
   Mix_PauseAudio(true);
   #else
   SDL_PauseAudio(true);
   #endif
}

void ResumeSdlSound()
{
   #ifdef NME_SDL3
   if (sSdlSoundDevice)
      SDL_ResumeAudioDevice(sSdlSoundDevice);
   #endif

   sSoundPaused = false;
   if (gSDLAudioState!=sdaOpen)
     return;

   #ifdef NME_SDL3
   Mix_PauseAudio(false);
   #else
   SDL_PauseAudio(false);
   #endif
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
   #if defined(HX_WINDOWS) || defined(HX_MACOS)
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
