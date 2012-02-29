package nme.media;

#if (cpp || neko)

typedef SoundChannel = neash.media.SoundChannel;

#elseif js

typedef SoundChannel = jeash.media.SoundChannel;

#else

typedef SoundChannel = flash.media.SoundChannel;

#end