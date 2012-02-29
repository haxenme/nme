package nme.display;

#if (cpp || neko)

typedef MovieClip = neash.display.MovieClip;

#elseif js

typedef MovieClip = jeash.display.MovieClip;

#else

typedef MovieClip = flash.display.MovieClip;

#end