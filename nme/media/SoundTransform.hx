package nme.media;

#if (cpp || neko)

typedef SoundTransform = neash.media.SoundTransform;

#elseif js

typedef SoundTransform = jeash.media.SoundTransform;

#else

typedef SoundTransform = flash.media.SoundTransform;

#end