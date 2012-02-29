package nme.display;

#if (cpp || neko)

typedef Shape = neash.display.Shape;

#elseif js

typedef Shape = jeash.display.Shape;

#else

typedef Shape = flash.display.Shape;

#end