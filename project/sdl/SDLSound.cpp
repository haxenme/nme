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


static bool Init()
{
   if (!gSDLIsInit)
   {
      //if (SDL_Init(SDL_INIT_AUDIO) != -1)
         gSDLIsInit = true;

		if (Mix_OpenAudio(44100, AUDIO_S16SYS, 2, 4096) < 0)
		{
			printf("Could not start mixer: %s\n", SDL_GetError());
		}
   }

   if (gSDLIsInit && !sChannelsInit)
   {
		sChannelsInit = true;
      for(int i=0;i<sMaxChannels;i++)
      {
         sUsedChannel[i] = false;
         sDoneChannel[i] = false;
      }
      Mix_ChannelFinished(onChannelDone);
      Mix_HookMusicFinished(onMusicDone);
   }

   return gSDLIsInit;
}

// ---  Using "Mix_Chunk" API ----------------------------------------------------

class SDLSoundChannel : public SoundChannel
{
public:
   SDLSoundChannel(Object *inSound, Mix_Chunk *inChunk, double inStartTime, int inLoops,
                  const SoundTransform &inTransform)
   {
      mChunk = inChunk;
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
   ~SDLSoundChannel()
   {
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

   Object    *mSound;
   Mix_Chunk *mChunk;
   int       mChannel;
};




class SDLSound : public Sound
{
public:
   SDLSound(const std::string &inFilename)
   {
		IncRef();
      mChunk = Mix_LoadWAV(inFilename.c_str());
      if ( mChunk == NULL )
		{
         mError = SDL_GetError();
			//printf("Error %s\n", mError.c_str() );
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
      return mChunk->length_ticks;
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
      mMusic = Mix_LoadMUS(inFilename.c_str());
      if ( mMusic == NULL )
		{
         mError = SDL_GetError();
			//printf("Error %s\n", mError.c_str() );
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
