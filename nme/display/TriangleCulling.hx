package nme.display;


#if flash
@:native ("flash.display.TriangleCulling")
@:fakeEnum(String) extern enum TriangleCulling {
	NEGATIVE;
	NONE;
	POSITIVE;
}
#else



enum TriangleCulling
{
   NEGATIVE;
   NONE;
   POSITIVE;
}
#end