#include <Sound.h>
#include <Display.h>
#include <SDL.h>


namespace nme
{

bool gSDLIsInit = false;

static bool Init()
{
	if (!gSDLIsInit)
	{
		if (SDL_Init(SDL_INIT_AUDIO) != -1)
			gSDLIsInit = true;
		else
			return false;
	}
	return true;
}



class SDLSound : public Sound
{
public:
   SDLSound(const std::wstring &inFilename)
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
	return new SDLSound(inFilename);
}




}
