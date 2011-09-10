#if flash


package nme.display;


@:native ("flash.display.ColorCorrectionSupport")
@:fakeEnum(String) extern enum ColorCorrectionSupport {
	DEFAULT_OFF;
	DEFAULT_ON;
	UNSUPPORTED;
}



#end