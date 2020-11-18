#ifndef AUDIO_H
#define AUDIO_H

#include <nme/QuickVec.h>
#include <Sound.h>
#include <Utils.h>

#ifdef ANDROID
#include <android/log.h>
#endif


#if 0
   #ifdef ANDROID
      #define LOG_SOUND(args,...) ELOG(args, ##__VA_ARGS__);
   #elif defined(IPHONE)
      #define LOG_SOUND(args,...) NmeLog(args, ##__VA_ARGS__);
   #elif defined(TIZEN)
      #include <FBase.h>
      #define LOG_SOUND(args,...) AppLog(args, ##__VA_ARGS__);
   #else
      #define LOG_SOUND(args,...) printf(args, ##__VA_ARGS__);
   #endif
#else
   #define LOG_SOUND(args,...)  { }
#endif


namespace nme
{

Sound *CreateAndroidSound(const unsigned char *inData, int len, bool inForceMusic);
Sound *CreateAndroidSound(const std::string &inFilename,bool inForceMusic);


Sound *CreateSdlSound(const unsigned char *inData, int len, bool inForceMusic);
Sound *CreateSdlSound(const std::string &inFilename,bool inForceMusic);
SoundChannel *CreateSdlSyncChannel(const ByteArray &inData, const SoundTransform &inTransform,
              SoundDataFormat inDataFormat,bool inIsStereo, int inRate);
SoundChannel *CreateSdlAsyncChannel( SoundDataFormat inDataFormat,bool inIsStereo, int inRate, void *inCallback);
void SuspendSdlSound();
void ResumeSdlSound();
void avSuspendAudio();
void avResumeAudio();

Sound *CreateAvPlayerSound(const unsigned char *inData, int len);
Sound *CreateAvPlayerSound(const std::string &inFilename);

Sound *CreateOpenAlSound(const unsigned char *inData, int len, bool inForceMusic);
SoundChannel *CreateOpenAlSyncChannel(const ByteArray &inData, const SoundTransform &inTransform,
              SoundDataFormat inDataFormat,bool inIsStereo, int inRate);
void SuspendOpenAl();
void ResumeOpenAl();
void ShutdownOpenAl();
void PingOpenAl();

Sound *CreateOpenSlSound(const unsigned char *inData, int len, bool inForceMusic);
SoundChannel *CreateOpenSlSyncChannel(const ByteArray &inData, const SoundTransform &inTransform,
              SoundDataFormat inDataFormat,bool inIsStereo, int inRate);



class INmeSoundData;
class INmeSoundStream;

enum
{
   SoundForceDecode = 0x0001,
   SoundJustInfo    = 0x0002,
};



enum AudioFormat
{
   eAF_unknown,
   eAF_ogg,
   eAF_wav,
   eAF_mid,
   eAF_mp3,
   eAF_count
};

AudioFormat determineFormatFromBytes(const unsigned char *inData, int len);
AudioFormat determineFormatFromFile(const std::string &inFilename);



class INmeSoundData
{
public:
   static INmeSoundData *create(const std::string &inId, unsigned int inFlags=0x0000);
   static INmeSoundData *createAvDecoded(const std::string &inId);
   static INmeSoundData *create(const unsigned char *inData, int inDataLength, unsigned int inFlags=0x0000);
   static INmeSoundData *createAcm(const unsigned char *inData, int inDataLength, unsigned int inFlags=0x0000);
   static INmeSoundData *create(const short *inData, int inChannelSamples, bool inIsStereo, int inRate);

   virtual INmeSoundData  *addRef() = 0;
   virtual void   release() = 0;
   virtual double getDuration() const = 0;
   virtual int    getChannelSampleCount() const = 0;
   virtual bool   getIsStereo() const = 0;
   virtual int    getRate() const = 0;
   virtual bool   getIsDecoded() const = 0;
   virtual short  *decodeAll() = 0;
   virtual int    getDecodedByteCount() const = 0;
   virtual INmeSoundStream *createStream()=0;

   virtual bool isValid() const { return getChannelSampleCount(); }
protected:
   // Call "release"
   ~INmeSoundData() { }
};



class INmeSoundStream 
{
public:
   virtual ~INmeSoundStream() { }

   virtual double getPosition() = 0;
   virtual double setPosition(double inSeconds) = 0;
   virtual void   rewind() = 0;
   virtual double getDuration() const = 0;
   virtual int    getRate() const = 0;
   virtual int    getChannelSampleCount() const = 0;
   virtual bool   getIsStereo() const = 0;
   virtual bool   isValid() const { return getChannelSampleCount(); }

   virtual int    fillBuffer(char *outBuffer, int inRequestBytes) = 0;
};


}

#endif
