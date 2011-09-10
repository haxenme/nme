#if flash


package nme.display;


@:native ("flash.display.GradientType")
@:fakeEnum(String) extern enum GradientType {
	LINEAR;
	RADIAL;
}



#else


package nme.display;

enum GradientType { RADIAL; LINEAR; }


#end