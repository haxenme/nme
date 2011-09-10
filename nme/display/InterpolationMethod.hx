package nme.display;


#if flash
@:native ("flash.display.InterpolationMethod")
@:fakeEnum(String) extern enum InterpolationMethod {
	LINEAR_RGB;
	RGB;
}
#else



enum InterpolationMethod { RGB; LINEAR_RGB; }
#end