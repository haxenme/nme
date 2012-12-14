package nme.display;
#if display


extern interface IBitmapDrawable {
}


#elseif (cpp || neko)
typedef IBitmapDrawable = native.display.IBitmapDrawable;
#elseif js
typedef IBitmapDrawable = jeash.display.IBitmapDrawable;
#else
typedef IBitmapDrawable = flash.display.IBitmapDrawable;
#end
