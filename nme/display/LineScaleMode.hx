package nme.display;
#if (cpp || neko || js)


enum LineScaleMode
{	
	NORMAL; // default
	NONE;
	VERTICAL;
	HORIZONTAL;	
}


#else
typedef LineScaleMode = flash.display.LineScaleMode;
#end