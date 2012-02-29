package nme.display;

#if (cpp || neko)

typedef LineScaleMode = neash.display.LineScaleMode;

#elseif js

typedef LineScaleMode = jeash.display.LineScaleMode;

#else

typedef LineScaleMode = flash.display.LineScaleMode;

#end