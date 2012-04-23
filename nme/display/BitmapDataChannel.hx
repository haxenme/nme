package nme.display;
#if code_completion


extern class BitmapDataChannel {
	public static inline var ALPHA = 8;
	public static inline var BLUE = 4;
	public static inline var GREEN = 2;
	public static inline var RED = 1;
}


#elseif (cpp || neko)
typedef BitmapDataChannel = neash.display.BitmapDataChannel;
#elseif js
typedef BitmapDataChannel = jeash.display.BitmapDataChannel;
#else
typedef BitmapDataChannel = flash.display.BitmapDataChannel;
#end