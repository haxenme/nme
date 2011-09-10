#if flash


package nme.display;


@:native ("flash.display.JointStyle")
@:fakeEnum(String) extern enum JointStyle {
	BEVEL;
	MITER;
	ROUND;
}



#else


package nme.display;

enum JointStyle
{
   ROUND; // Default
   MITER;
   BEVEL;
}


#end