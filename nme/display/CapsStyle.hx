package nme.display;


#if flash
@:native ("flash.display.CapsStyle")
@:fakeEnum(String) extern enum CapsStyle {
	NONE;
	ROUND;
	SQUARE;
}
#else



enum CapsStyle
{
   ROUND; // Default
   NONE;
   SQUARE;
}
#end