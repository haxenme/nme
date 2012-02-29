package nme.media;

#if (cpp || neko)

typedef SoundLoaderContext = neash.media.SoundLoaderContext;

#elseif js

typedef SoundLoaderContext = jeash.media.SoundLoaderContext;

#else

typedef SoundLoaderContext = flash.media.SoundLoaderContext;

#end