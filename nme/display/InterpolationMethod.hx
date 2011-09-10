#if flash


package nme.display;


@:native ("flash.display.InterpolationMethod")
@:fakeEnum(String) extern enum InterpolationMethod {
	LINEAR_RGB;
	RGB;
}



#else


package nme.display;

enum InterpolationMethod { RGB; LINEAR_RGB; }


#end