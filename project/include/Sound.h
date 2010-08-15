#ifndef SOUND_H
#define SOUND_H

#include <string>

#include "Object.h"

namespace nme
{

struct SoundTransform
{
   SoundTransform() : pan(0), volume(1.0) { }
   double pan;
   double volume;
};

class SoundChannel : public Object
{
public:
   virtual bool isComplete() = 0;
   virtual double getLeft() = 0;
   virtual double getRight() = 0;
   virtual double getPosition() = 0;
   virtual void stop() = 0;
   virtual void setTransform(const SoundTransform &inTransform) = 0;
};



class Sound : public Object
{
public:
   static Sound *Create(const std::string &inFilename, bool inForceMusic);

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
};

} // end namespace nme

#endif

