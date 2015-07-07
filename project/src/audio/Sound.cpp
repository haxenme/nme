#include <Sound.h>
#include "Audio.h"


namespace nme
{

typedef Sound *(*factory)(const unsigned char *inData, int inLen);

Sound *ReadAndCreate(const std::string &inFilename, factory onLoaded)
{
   ByteArray data(inFilename.c_str());
   if (data.Size()>0)
      return onLoaded( data.Bytes(), data.Size() );
   return 0;
}


Sound *Sound::FromFile(const std::string &inFilename, bool inForceMusic)
{
   Sound *result = 0;

   #ifdef HX_ANDROID

   result = CreateAndroidSound(inFilename,inForceMusic);

   #elif defined(IPHONE)

   AudioFormat format = determineFormatFromFile(inFilename);

   if (format==eAF_mp3 || (inForceMusic && format!=eAF_ogg && format!=eAF_mid ) )
      result = CreateAvPlayerSound(inFilename);
   else
      result = ReadAndCreate(inFilename, CreateOpenAlSound);

   #else

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

Sound *Sound::FromEncodedBytes(const unsigned char *inData, int inLen, bool inForceMusic)
{
   Sound *result = 0;

   #ifdef HX_ANDROID

   // Maybe use opensl here ....
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
      result = CreateOpenAlSound(inData, inLen);

   #else

    #ifdef HX_MACOS
    // Openal can be tested on mac
    if (false)
    {
      result = CreateOpenAlSound(inData, inLen);
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

   #else

   result = CreateSdlSyncChannel(inData, inTransform, inDataFormat, inIsStereo, inRate);

   #endif

   if (!result)
      ELOG("Error creating sync sound ");

   return result;
}



}

