#include <OpenAL/AL.h>
#include <Sound.h>

namespace nme
{

static ALCdevice  *sgDevice = 0;
static ALCcontext *sgContext = 0;

static bool Init()
{
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


class OpenALSound : public Sound
{
public:
   OpenALSound(const std::wstring &inFilename)
	{
	}
	double getLength()
	{
		return 0.0;
	}
	SoundChannel *openChannel(double startTime, int loops, const SoundTransform &inTransform)
	{
		return 0;
	}
};


Sound *Sound::Create(const std::wstring &inFilename)
{
	if (!Init())
		return 0;
	return new OpenALSound(inFilename);
}



}
