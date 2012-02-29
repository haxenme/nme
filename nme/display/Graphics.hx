package nme.display;

#if (cpp || neko)

typedef Graphics = neash.display.Graphics;

#elseif js

typedef Graphics = jeash.display.Graphics;

#else

typedef Graphics = flash.display.Graphics;

#end