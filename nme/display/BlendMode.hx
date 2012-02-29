package nme.display;

#if (cpp || neko)

typedef BlendMode = neash.display.BlendMode;

#elseif js

typedef BlendMode = jeash.display.BlendMode;

#else

typedef BlendMode = flash.display.BlendMode;

#end