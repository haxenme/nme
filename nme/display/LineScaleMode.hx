package nme.display;


#if flash
@:native ("flash.display.LineScaleMode")
@:fakeEnum(String) extern enum LineScaleMode {
	HORIZONTAL;
	NONE;
	NORMAL;
	VERTICAL;
}
#else



enum LineScaleMode
{
   NORMAL; // Default
   NONE;
   VERTICAL;
   HORIZONTAL;
}
#end