#if flash


package nme.display;


@:native ("flash.display.CapsStyle")
@:fakeEnum(String) extern enum CapsStyle {
	NONE;
	ROUND;
	SQUARE;
}


#else


package nme.display;

enum CapsStyle
{
   ROUND; // Default
   NONE;
   SQUARE;
}


#end