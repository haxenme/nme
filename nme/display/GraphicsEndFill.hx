package nme.display;

#if (cpp || neko)

typedef GraphicsEndFill = neash.display.GraphicsEndFill;

#elseif js

typedef GraphicsEndFill = jeash.display.GraphicsEndFill;

#else

typedef GraphicsEndFill = flash.display.GraphicsEndFill;

#end