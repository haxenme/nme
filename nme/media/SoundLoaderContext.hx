package nme.media;
#if cpp || neko


class SoundLoaderContext
{
   public function new()
	{
	}
}


#else
typedef SoundLoaderContext = flash.media.SoundLoaderContext;
#end