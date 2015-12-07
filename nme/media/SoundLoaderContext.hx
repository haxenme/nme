package nme.media;
#if (!flash)

class SoundLoaderContext 
{
   public function new() 
   {
   }
}

#else
typedef SoundLoaderContext = flash.media.SoundLoaderContext;
#end
