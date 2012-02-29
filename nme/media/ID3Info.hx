package nme.media;

#if (cpp || neko)

typedef ID3Info = neash.media.ID3Info;

#elseif js

typedef ID3Info = jeash.media.ID3Info;

#else

typedef ID3Info = flash.media.ID3Info;

#end