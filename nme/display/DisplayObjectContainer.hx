package nme.display;

#if (cpp || neko)

typedef DisplayObjectContainer = neash.display.DisplayObjectContainer;

#elseif js

typedef DisplayObjectContainer = jeash.display.DisplayObjectContainer;

#else

typedef DisplayObjectContainer = flash.display.DisplayObjectContainer;

#end