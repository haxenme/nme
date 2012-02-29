package nme.display;

#if (cpp || neko)

typedef BitmapData = neash.display.BitmapData;

#elseif js

typedef BitmapData = jeash.display.BitmapData;

#else

typedef BitmapData = flash.display.BitmapData;

#end