package nme.display;
#if (cpp || neko)


class BitmapDataChannel
{
	static public inline var ALPHA = 0x0008;
	static public inline var BLUE = 0x0004;
	static public inline var GREEN = 0x0002;
	static public inline var RED = 0x0001;
}


#else
typedef BitmapDataChannel = flash.display.BitmapDataChannel;
#end