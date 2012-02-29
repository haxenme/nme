package nme.display;

#if (cpp || neko)

typedef DisplayObject = neash.display.DisplayObject;

#elseif js

typedef DisplayObject = jeash.display.DisplayObject;

#else

typedef DisplayObject = flash.display.DisplayObject;

#end