#ifndef INCLUDED_OPENALSOUND_H
#define INCLUDED_OPENALSOUND_H


#if defined(HX_MACOS) || defined(IPHONE)
#include <OpenAL/al.h>
#include <OpenAL/alc.h>
#else
#include <AL/al.h>
#include <AL/alc.h>
#endif

#include <Sound.h>
#include <QuickVec.h>
#include <Utils.h>
#include <Audio.h>


typedef unsigned char uint8;


namespace nme
{


static ALCdevice  *sgDevice = 0;
static ALCcontext *sgContext = 0;

static bool OpenALInit()
{
   //LOG_SOUND("Sound.mm OpenALInit()");
   
   static bool is_init = false;
   if (!is_init)
   {
      is_init = true;
      sgDevice = alcOpenDevice(0); // select the "preferred device"
      if (sgDevice)
      {
         sgContext=alcCreateContext(sgDevice,0);
         alcMakeContextCurrent(sgContext);
      }
   }
   return sgContext;
}


class OpenALChannel : public SoundChannel
{
public:
   OpenALChannel(Object *inSound, unsigned int inBufferID, int startTime, int inLoops, const SoundTransform &inTransform);
   OpenALChannel(const ByteArray &inBytes,const SoundTransform &inTransform);
   void QueueBuffer(ALuint inBuffer, const ByteArray &inBytes);
   void unqueueBuffers();
   bool needsData();
   void addData(const ByteArray &inBytes);
   bool isComplete();
   double getLeft();
   double getRight();
   double setPosition(const float &inFloat);
   double getPosition();
   void setTransform(const SoundTransform &inTransform);
   void stop();
   
protected:
   ~OpenALChannel();
   Object *mSound;
   unsigned int mSourceID;
   short  *mSampleBuffer;
   bool   mDynamicDone;
   ALuint mDynamicStackSize;
   ALuint mDynamicStack[2];
   ALuint mDynamicBuffer[2];
   enum { STEREO_SAMPLES = 2 };
   
};


class OpenALSound : public Sound
{
public:
   OpenALSound(const std::string &inFilename);
   OpenALSound(float *inData, int len);
   double getLength();
   void getID3Value(const std::string &inKey, std::string &outValue);
   int getBytesLoaded();
   int getBytesTotal();
   bool ok();
   std::string getError();
   void close();
   SoundChannel *openChannel(double startTime, int loops, const SoundTransform &inTransform);
   
protected:
   ~OpenALSound();
   ALint bufferSize;
   ALint frequency;
   ALint bitsPerSample;
   ALint channels;

   unsigned int mBufferID;
   std::string mError;
        
};


}


#endif
