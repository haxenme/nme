#include <Sound.h>
#include <Display.h>
#include <SDL.h>
#include <SDL_mixer.h>

#include <hx/Thread.h>


namespace nme
{

bool gSDLIsInit = false;

class SDLSoundChannel;

MyMutex sChannelListLock;
bool sChannelsInit = false;
enum { sMaxChannels = 32 };

SDLSoundChannel *sChannel[sMaxChannels];
bool sDoneChannel[sMaxChannels];

void onSdlMixerChannelDone(int inChannel);

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
         sChannel[i] = 0;
         sDoneChannel[i] = false;
      }
      Mix_ChannelFinished(onSdlMixerChannelDone);
   }

   return gSDLIsInit;
}

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
         AutoLock lock(sChannelListLock);
         for(int i=0;i<sMaxChannels;i++)
            if (!sChannel[i])
            {
               IncRef();
               sChannel[i] = this;
               sDoneChannel[i] = false;
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
         sChannel[c]->DecRef();
         sChannel[c] = 0;
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

void onSdlMixerChannelDone(int inChannel)
{
   AutoLock lock(sChannelListLock);
   if (sChannel[inChannel])
      sDoneChannel[inChannel] = true;
}




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


Sound *Sound::Create(const std::string &inFilename)
{
   if (!Init())
      return 0;
   return new SDLSound(inFilename);
}



}
