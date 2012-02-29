package nme.display;

#if (cpp || neko)

typedef GraphicsSolidFill = neash.display.GraphicsSolidFill;

#elseif js

typedef GraphicsSolidFill = jeash.display.GraphicsSolidFill;

#else

typedef GraphicsSolidFill = flash.display.GraphicsSolidFill;

#end