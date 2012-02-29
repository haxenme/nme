package nme.display;

#if (cpp || neko)

typedef GraphicsPath = neash.display.GraphicsPath;

#elseif js

typedef GraphicsPath = jeash.display.GraphicsPath;

#else

typedef GraphicsPath = flash.display.GraphicsPath;

#end