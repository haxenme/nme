#if flash


package nme.display;


@:native ("flash.display.PixelSnapping")
@:fakeEnum(String) extern enum PixelSnapping {
	ALWAYS;
	AUTO;
	NEVER;
}



#else


package nme.display;

enum PixelSnapping {
		NEVER;
		AUTO;
		ALWAYS;
}


#end