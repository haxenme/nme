#if flash


package nme.display;


@:native ("flash.display.TriangleCulling")
@:fakeEnum(String) extern enum TriangleCulling {
	NEGATIVE;
	NONE;
	POSITIVE;
}



#else


package nme.display;

enum TriangleCulling
{
   NEGATIVE;
   NONE;
   POSITIVE;
}


#end