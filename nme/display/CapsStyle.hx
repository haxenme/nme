package nme.display;
#if (cpp || neko)


enum CapsStyle {
	
	ROUND; // default
	NONE;
	SQUARE;
	
}


#else
typedef CapsStyle = flash.display.CapsStyle;
#end