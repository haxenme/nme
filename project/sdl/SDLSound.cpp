#include <Sound.h>
#include <Display.h>
#include <SDL.h>
#include <SDL_mixer.h>

#include <hx/Thread.h>


namespace nme
{

bool gSDLIsInit = false;

class SDLSoundChannel;

bool sChannelsInit = false;
enum { sMaxChannels = 8 };

bool sUsedChannel[sMaxChannels];
bool sDoneChannel[sMaxChannels];
void *sUsedMusic = 0;
bool sDoneMusic = false;

unsigned int  sSoundPos = 0;

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

void  onPostMix(void *udata, Uint8 *stream, int len)
{
   sSoundPos += len;
}


static bool Init()
{
   if (!gSDLIsInit)
   {
      fprintf(stderr,"Please init Stage before creating sound.\n");
      return false;
   }

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
      Mix_SetPostMix(onPostMix,0);
   }

   return sChannelsInit;
}

// ---  Using "Mix_Chunk" API ----------------------------------------------------


class SDLSoundChannel : public SoundChannel
{
  enum { BUF_SIZE = 16384 };

public:
   SDLSoundChannel(Object *inSound, Mix_Chunk *inChunk, double inStartTime, int inLoops,
                  const SoundTransform &inTransform)
   {
      mChunk = inChunk;
      mDynamicBuffer = 0;
      mSound = inSound;
      mSound->IncRef();

      mChannel = -1;

      // Allocate myself a channel
      if (mChunk)
      {
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

      if (mChannel>=0)
      {
         Mix_PlayChannel( mChannel , mChunk, inLoops<0 ? -1 : inLoops==0 ? 0 : inLoops-1 );
         Mix_Volume( mChannel, inTransform.volume*MIX_MAX_VOLUME );
         // Mix_SetPanning
      }
   }

   SDLSoundChannel(const ByteArray &inBytes, const SoundTransform &inTransform)
   {
      mChunk = 0;
      mDynamicBuffer = new short[BUF_SIZE];
      memset(mDynamicBuffer,0,BUF_SIZE*sizeof(short));
      mSound = 0;
      mChannel = -1;
      mDynamicChunk.allocated = 0;
      mDynamicChunk.abuf = (Uint8 *)mDynamicBuffer;
      mDynamicChunk.alen = BUF_SIZE;
      mDynamicChunk.volume = MIX_MAX_VOLUME;
	   mDynamicChunk.length_ticks = 0;
      mDynamicFillPos = 0;
      mDynamicStartPos = 0;
      mDynamicDataDue = 0;
  
      Mix_QuerySpec(&mFrequency, &mFormat, &mChannels);

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

      if (mChannel>=0)
      {
         FillBuffer(inBytes);
         // Just once ...
         if (mDynamicFillPos<2048)
         {
            mDynamicDone = true;
            mDynamicChunk.alen = mDynamicFillPos;
            Mix_PlayChannel( mChannel , &mDynamicChunk,  0 );
         }
         else
         {
            mDynamicDone = false;
            Mix_PlayChannel( mChannel , &mDynamicChunk,  -1 );
            // TODO: Lock?
            mDynamicStartPos = sSoundPos;
         }

         Mix_Volume( mChannel, inTransform.volume*MIX_MAX_VOLUME );
      }
   }

   void FillBuffer(const ByteArray &inBytes)
   {
      int floats = inBytes.Size()/sizeof(float);
      const float *buffer = (const float *)inBytes.Bytes();
      int pos = mDynamicFillPos & (BUF_SIZE-1);
      mDynamicFillPos += floats;

      int first = std::min( floats, BUF_SIZE-pos );
      for(int i=0;i<first;i++)
         mDynamicBuffer[pos+i] = *buffer++ * 16385;

      if (first<floats)
      {
         floats -= first;
         for(int i=0;i<floats;i++)
            mDynamicBuffer[i] = *buffer++ * 16385;
      }
   }
 
   ~SDLSoundChannel()
   {
      delete [] mDynamicBuffer;

      if (mSound)
         mSound->DecRef();
   }

   void CheckDone()
   {
      if (mChannel>=0 && sDoneChannel[mChannel])
      {
         sDoneChannel[mChannel] = false;
         int c = mChannel;
         mChannel = -1;
         DecRef();
         sUsedChannel[c] = 0;
      }
   }

   bool isComplete()
   {
      CheckDone();
      return mChannel < 0;
   }
   double getLeft() { return 1; }
   double getRight() { return 1; }
   double getPosition() { return 1; }
   void stop() 
   {
      if (mChannel>=0)
         Mix_HaltChannel(mChannel);
   }
   void setTransform(const SoundTransform &inTransform) 
   {
      if (mChannel>=0)
         Mix_Volume( mChannel, inTransform.volume*MIX_MAX_VOLUME );
   }

   double getDataPosition()
   {
      int pos = (sSoundPos-mDynamicStartPos)*1000.0/mFrequency;
   }
   bool needsData()
   {
      if (!mDynamicBuffer || mDynamicDone)
         return false;

      if (mDynamicDataDue<=sSoundPos)
      {
         mDynamicDone = true;
         return true;
      }

      return false;

   }

   void addData(const ByteArray &inBytes)
   {
      mDynamicDone = false;
      mDynamicDataDue = mDynamicFillPos + mDynamicStartPos;
      FillBuffer(inBytes);
   }


   Object    *mSound;
   Mix_Chunk *mChunk;
   int       mChannel;

   Mix_Chunk mDynamicChunk;
   short    *mDynamicBuffer;
   unsigned int  mDynamicFillPos;
   unsigned int  mDynamicStartPos;
   unsigned int  mDynamicDataDue;
   bool      mDynamicDone;
   int       mFrequency;
   Uint16    mFormat;
   int       mChannels;
};

SoundChannel *SoundChannel::Create(const ByteArray &inBytes,const SoundTransform &inTransform)
{
   return new SDLSoundChannel(inBytes,inTransform);
}



class SDLSound : public Sound
{
public:
   SDLSound(const std::string &inFilename)
   {
      IncRef();

      #ifdef HX_MACOS
      char name[1024];
      GetBundleFilename(inFilename.c_str(),name,1024);
      #else
      const char *name = inFilename.c_str();
      #endif

      mChunk = Mix_LoadWAV(name);
      if ( mChunk == NULL )
      {
         mError = SDL_GetError();
         // printf("Error %s (%s)\n", mError.c_str(), name );
      }
   }
   ~SDLSound()
   {
      if (mChunk)
         Mix_FreeChunk( mChunk );
   }
   double getLength()
   {
      if (mChunk==0) return 0;
      #if defined(DYNAMIC_SDL) || defined(WEBOS)
      // ?
      return 0.0;
      #else
	  return 0.0;
      //return mChunk->length_ticks;
      #endif
   }
   // Will return with one ref...
   SoundChannel *openChannel(double startTime, int loops, const SoundTransform &inTransform)
   {
      if (!mChunk)
         return 0;
      return new SDLSoundChannel(this,mChunk,startTime, loops,inTransform);
   }
   int getBytesLoaded() { return mChunk ? mChunk->alen : 0; }
   int getBytesTotal() { return mChunk ? mChunk->alen : 0; }
   bool ok() { return mChunk; }
   std::string getError() { return mError; }


   std::string mError;
   Mix_Chunk *mChunk;
};

// ---  Using "Mix_Music" API ----------------------------------------------------


class SDLMusicChannel : public SoundChannel
{
public:
   SDLMusicChannel(Object *inSound, Mix_Music *inMusic, double inStartTime, int inLoops,
                  const SoundTransform &inTransform)
   {
      mMusic = inMusic;
      mSound = inSound;
      mSound->IncRef();

      mPlaying = false;
      if (mMusic)
      {
         mPlaying = true;
         sUsedMusic = this;
         sDoneMusic = false;
         IncRef();
         Mix_PlayMusic( mMusic, inLoops<0 ? -1 : inLoops==0 ? 0 : inLoops-1 );
         Mix_VolumeMusic( inTransform.volume*MIX_MAX_VOLUME );
         // Mix_SetPanning
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
   double getPosition() { return 1; }
   void stop() 
   {
      if (mMusic)
         Mix_HaltMusic();
   }
   void setTransform(const SoundTransform &inTransform) 
   {
      if (mMusic>=0)
         Mix_VolumeMusic( inTransform.volume*MIX_MAX_VOLUME );
   }

   bool      mPlaying;
   Object    *mSound;
   Mix_Music *mMusic;
};


class SDLMusic : public Sound
{
public:
   SDLMusic(const std::string &inFilename)
   {
      IncRef();

      #ifdef HX_MACOS
      char name[1024];
      GetBundleFilename(inFilename.c_str(),name,1024);
      #else
      const char *name = inFilename.c_str();
      #endif

      mMusic = Mix_LoadMUS(name);
      if ( mMusic == NULL )
      {
         mError = SDL_GetError();
         printf("Error %s (%s)\n", mError.c_str(), name );
      }
   }
   ~SDLMusic()
   {
      if (mMusic)
         Mix_FreeMusic( mMusic );
   }
   double getLength()
   {
      if (mMusic==0) return 0;
      // TODO:
      return 60000;
   }
   // Will return with one ref...
   SoundChannel *openChannel(double startTime, int loops, const SoundTransform &inTransform)
   {
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


Sound *Sound::Create(const std::string &inFilename,bool inForceMusic)
{
   if (!Init())
      return 0;
   Sound *sound = inForceMusic ? 0 :  new SDLSound(inFilename);
   if (!sound || !sound->ok())
   {
      if (sound) sound->DecRef();
      sound = new SDLMusic(inFilename);
   }
   return sound;
}



}
