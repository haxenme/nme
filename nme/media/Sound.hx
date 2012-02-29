package nme.media;

#if (cpp || neko)

typedef Sound = neash.media.Sound;

#elseif js

typedef Sound = jeash.media.Sound;

#else

typedef Sound = flash.media.Sound;

#end