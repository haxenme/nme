package nme.display;

#if (cpp || neko)

typedef Bitmap = neash.display.Bitmap;

#elseif js

typedef Bitmap = jeash.display.Bitmap;

#else

typedef Bitmap = flash.display.Bitmap;

#end