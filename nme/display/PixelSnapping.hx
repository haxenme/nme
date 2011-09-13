package nme.display;
#if cpp || neko


enum PixelSnapping {
		NEVER;
		AUTO;
		ALWAYS;
}


#else
typedef PixelSnapping = flash.display.PixelSnapping;
#end