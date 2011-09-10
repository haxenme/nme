package nme.display;


#if flash
@:native ("flash.display.GradientType")
@:fakeEnum(String) extern enum GradientType {
	LINEAR;
	RADIAL;
}
#else



enum GradientType { RADIAL; LINEAR; }
#end