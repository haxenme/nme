#ifndef SOUND_H
#define SOUND_H

#include <string>

#include <nme/Object.h>
#include "ByteArray.h"

namespace nme
{

enum SDLAudioState
{
   sdaNotInit = 0,
   sdaOpen = 1,
   sdaClosed = 2,
   sdaError = 3,
};

extern SDLAudioState gSDLAudioState;

void InitSDLAudio();

// Channel lists...
void clLock();
void clUnlock();
void clResumeAllChannels();
void clSuspendAllChannels();
void clShutdown();
class SoundChannel;
void clAddChannel(SoundChannel *inChannel,bool inIsAsync);
void clRemoveChannel(SoundChannel *inChannel);

struct SoundTransform
{
   SoundTransform() : pan(0), volume(1.0) { }
   double pan;
   double volume;
};

enum SoundDataFormat
{
   sdfByte,
   sdfShort,
   sdfFloat,
};

class SoundChannel : public Object
{
public:
   static SoundChannel *CreateSyncChannel(const ByteArray &inData, const SoundTransform &inTransform,
              SoundDataFormat inDataFormat=sdfFloat,bool inIsStereo=true, int inRate=44100) ;

   static SoundChannel *CreateAsyncChannel(SoundDataFormat inDataFormat,bool inIsStereo, int inRate, void *inCallback, const std::string &inEngine );

   static void PerformAsyncCallback(void *inCallback);
   static void DestroyAsyncCallback(void *inCallback);

   NmeObjectType getObjectType() { return notSoundChannel; }

   virtual bool isComplete() = 0;
   virtual double getLeft() = 0;
   virtual double getRight() = 0;
   virtual double getPosition() = 0;
   virtual double setPosition(const float &inFloat) = 0;
   virtual void stop() = 0;
   virtual void setTransform(const SoundTransform &inTransform) = 0;

   virtual double getDataPosition() { return 0.0; }
   virtual bool needsData() { return false; }
   virtual void addData(const ByteArray &inBytes) { }
   virtual void asyncUpdate() { }
   virtual void suspend() { }
   virtual void resume() { }
};



class Sound : public Object
{
public:
   static Sound *FromFile(const std::string &inFilename, bool inForceMusic, const std::string &inEngine);
   static Sound *FromEncodedBytes(const unsigned char *inData, int len, bool inForceMusic, const std::string &inEngine);

   static void Suspend(unsigned int flags=0x01);
   static void Resume(unsigned int flags=0x01);
   static void Shutdown();

   virtual void getID3Value(const std::string &inKey, std::string &outValue)
   {
      outValue = "";
   }
   virtual int getBytesLoaded() = 0;
   virtual int getBytesTotal() = 0;
   virtual bool ok() = 0;
   virtual std::string getError() = 0;
   virtual double getLength() = 0;
   virtual void close()  { }
   virtual SoundChannel *openChannel(double startTime, int loops, const SoundTransform &inTransform) = 0;
   virtual const char *getEngine() { return "unknown"; }
   NmeObjectType getObjectType() { return notSound; }

};

} // end namespace nme

#endif

