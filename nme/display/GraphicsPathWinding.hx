package nme.display;

#if (cpp || neko)

typedef GraphicsPathWinding = neash.display.GraphicsPathWinding;

#elseif js

typedef GraphicsPathWinding = jeash.display.GraphicsPathWinding;

#else

typedef GraphicsPathWinding = flash.display.GraphicsPathWinding;

#end