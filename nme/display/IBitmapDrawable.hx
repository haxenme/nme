package nme.display;

#if (cpp || neko)

typedef IBitmapDrawable = neash.display.IBitmapDrawable;

#elseif js

typedef IBitmapDrawable = jeash.display.IBitmapDrawable;

#else

typedef IBitmapDrawable = flash.display.IBitmapDrawable;

#end