package nme.display;
#if (cpp || neko || js)


enum CapsStyle
{
	ROUND; // default
	NONE;
	SQUARE;
}


#else
typedef CapsStyle = flash.display.CapsStyle;
#end