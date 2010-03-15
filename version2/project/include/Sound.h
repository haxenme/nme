#ifndef SOUND_H
#define SOUND_H

#include <string>

#include "Object.h"

namespace nme
{

struct SoundTransform
{
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
	static Sound *Create(const std::wstring &inFilename);

	virtual void getID3Value(const std::wstring &inKey, std::wstring &outValue)
	{
		outValue = L"";
	}
	virtual double getLength() = 0;
	virtual SoundChannel *openChannel(double startTime, int loops, const SoundTransform &inTransform) = 0;
};

} // end namespace nme

#endif

