package nme.display;

#if (cpp || neko)

typedef GraphicsStroke = neash.display.GraphicsStroke;

#elseif js

typedef GraphicsStroke = jeash.display.GraphicsStroke;

#else

typedef GraphicsStroke = flash.display.GraphicsStroke;

#end