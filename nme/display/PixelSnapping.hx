package nme.display;


#if flash
@:native ("flash.display.PixelSnapping")
@:fakeEnum(String) extern enum PixelSnapping {
	ALWAYS;
	AUTO;
	NEVER;
}
#else



enum PixelSnapping {
		NEVER;
		AUTO;
		ALWAYS;
}
#end