package nme.display;
#if (cpp || neko || js)


enum PixelSnapping
{
	NEVER;
	AUTO;
	ALWAYS;
}


#else
typedef PixelSnapping = flash.display.PixelSnapping;
#end