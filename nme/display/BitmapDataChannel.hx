package nme.display;

#if (cpp || neko)

typedef BitmapDataChannel = neash.display.BitmapDataChannel;

#elseif js

typedef BitmapDataChannel = jeash.display.BitmapDataChannel;

#else

typedef BitmapDataChannel = flash.display.BitmapDataChannel;

#end