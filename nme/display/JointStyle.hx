package nme.display;


#if flash
@:native ("flash.display.JointStyle")
@:fakeEnum(String) extern enum JointStyle {
	BEVEL;
	MITER;
	ROUND;
}
#else



enum JointStyle
{
   ROUND; // Default
   MITER;
   BEVEL;
}
#end