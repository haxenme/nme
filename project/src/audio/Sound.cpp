#include <Sound.h>
#include "Audio.h"


namespace nme
{

typedef Sound *(*factory)(const unsigned char *inData, int inLen, bool inForceMusic);

Sound *ReadAndCreate(const std::string &inFilename, bool inForceMusic, factory onLoaded)
{
   ByteArray data(inFilename.c_str());
   if (data.Size()>0)
      return onLoaded( data.Bytes(), data.Size(), inForceMusic );
   else
     ELOG("Could not load sound file/resource %s", inFilename.c_str() );
   return 0;
}


Sound *Sound::FromFile(const std::string &inFilename, bool inForceMusic, const std::string &inEngine)
{
   Sound *result = 0;

   #ifdef HX_ANDROID

   if (inEngine=="opensl")
      result = ReadAndCreate(inFilename, inForceMusic, CreateOpenSlSound);
   else
      result = CreateAndroidSound(inFilename,inForceMusic);

   #elif defined(IPHONE)

   AudioFormat format = determineFormatFromFile(inFilename);

   if (format==eAF_mp3 || (inForceMusic && format!=eAF_ogg && format!=eAF_mid ) || inEngine=="avplayer"  )
      result = CreateAvPlayerSound(inFilename);
   else
      result = ReadAndCreate(inFilename, inForceMusic, CreateOpenAlSound);

   #elif defined(EMSCRIPTEN)
      result = ReadAndCreate(inFilename, inForceMusic, CreateOpenAlSound);
   #else

     #ifdef HX_MACOS
     if (inEngine=="openal")
        result = ReadAndCreate(inFilename, inForceMusic, CreateOpenAlSound);
     else
     #endif
   result = CreateSdlSound(inFilename,inForceMusic);

   #endif

   if (result && !result->ok())
   {
      result->DecRef();
      result = 0;
   }

   if (!result)
      ELOG("Error creating sound from filename %s", inFilename.c_str() );
   return result;
}

Sound *Sound::FromEncodedBytes(const unsigned char *inData, int inLen, bool inForceMusic, const std::string &inEngine)
{
   Sound *result = 0;

   #ifdef HX_ANDROID

   // Maybe use opensl here ....
   if (inEngine=="opensl")
      result = CreateOpenSlSound(inData, inLen, inForceMusic);
   else
      result = CreateAndroidSound(inData, inLen, inForceMusic);

   #elif defined(IPHONE)

   // AVPlayer must be used to play mp3 files
   // OpenAl must be used to play ogg and mid

   // OpenAl allows small files to be cached in buffers
   // AVPlayer as better hardware pathways

   AudioFormat format = determineFormatFromBytes(inData, inLen);

   if (format==eAF_mp3 || (inForceMusic && format!=eAF_ogg && format!=eAF_mid ) )
      result = CreateAvPlayerSound(inData,inLen);
   else
      result = CreateOpenAlSound(inData, inLen, inForceMusic);

   #elif defined(EMSCRIPTEN)
      result = CreateOpenAlSound(inData, inLen, inForceMusic);
   #else


    #ifdef HX_MACOS
    // Openal can be tested on mac
    if (inEngine=="openal")
    {
      result = CreateOpenAlSound(inData, inLen, inForceMusic);
    }
    else
    #endif

   result = CreateSdlSound(inData, inLen, inForceMusic);

   #endif

   if (result && !result->ok())
   {
      result->DecRef();
      result = 0;
   }

   if (!result)
      ELOG("Error creating sound from  %d bytes", inLen);

   return result;
}

SoundChannel *SoundChannel::CreateSyncChannel(const ByteArray &inData, const SoundTransform &inTransform,
              SoundDataFormat inDataFormat,bool inIsStereo, int inRate)
{
   SoundChannel *result = 0;
   #ifdef HX_ANDROID

   result = CreateOpenSlSyncChannel(inData, inTransform, inDataFormat, inIsStereo, inRate);

   #elif defined(IPHONE)

   result = CreateOpenAlSyncChannel(inData, inTransform, inDataFormat, inIsStereo, inRate);

   #elif defined(EMSCRIPTEN)

   result = CreateOpenAlSyncChannel(inData, inTransform, inDataFormat, inIsStereo, inRate);

   #else

   result = CreateSdlSyncChannel(inData, inTransform, inDataFormat, inIsStereo, inRate);

   #endif

   if (!result)
      ELOG("Error creating sync sound ");

   return result;
}


SoundChannel *SoundChannel::CreateAsyncChannel(SoundDataFormat inDataFormat,bool inIsStereo, int inRate, void *inCallback,
                                               const std::string &inEngine)

{
   SoundChannel *result = 0;
   #ifdef HX_ANDROID


   #elif defined(IPHONE)

   #elif defined(EMSCRIPTEN)

   #elif defined(HX_WINRT)


   #else

   result = CreateSdlAsyncChannel(inDataFormat, inIsStereo, inRate, inCallback);

   #endif

   if (!result)
   {
      ELOG("Error creating sync sound ");
      DestroyAsyncCallback(inCallback);
   }

   return result;
}




static bool sgSoundSuspended = false;

void Sound::Suspend()
{
   if (sgSoundSuspended)
      return;

   sgSoundSuspended = true;

   clSuspendAllChannels();

   #ifdef NME_OPENAL
   SuspendOpenAl();
   #endif

   #ifdef NME_MIXER
   SuspendSdlSound();
   #endif

}


void Sound::Resume()
{
   if (!sgSoundSuspended)
      return;

   sgSoundSuspended = false;

   #ifdef NME_OPENAL
   ResumeOpenAl();
   #endif

   #ifdef NME_MIXER
   ResumeSdlSound();
   #endif

   clResumeAllChannels();

   #ifdef NME_OPENAL
   PingOpenAl();
   #endif
}


void Sound::Shutdown()
{
   #ifdef NME_OPENAL
   ShutdownOpenAl();
   #endif
}

     



}

