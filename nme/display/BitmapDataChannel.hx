#if flash


package nme.display;

@:native ("flash.display.BitmapDataChannel")
extern class BitmapDataChannel {
	public static inline var ALPHA = 8;
	public static inline var BLUE = 4;
	public static inline var GREEN = 2;
	public static inline var RED = 1;
}



#else


package nme.display;

class BitmapDataChannel
{
   static public inline var ALPHA  = 0x0008;
   static public inline var BLUE   = 0x0004;
   static public inline var GREEN  = 0x0002;
   static public inline var RED    = 0x0001;
}


#end