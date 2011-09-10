package nme.display;


#if flash
@:native ("flash.display.ColorCorrection")
@:fakeEnum(String) extern enum ColorCorrection {
	DEFAULT;
	OFF;
	ON;
}
#end