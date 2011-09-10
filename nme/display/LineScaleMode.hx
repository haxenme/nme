#if flash


package nme.display;


@:native ("flash.display.LineScaleMode")
@:fakeEnum(String) extern enum LineScaleMode {
	HORIZONTAL;
	NONE;
	NORMAL;
	VERTICAL;
}



#else


package nme.display;

enum LineScaleMode
{
   NORMAL; // Default
   NONE;
   VERTICAL;
   HORIZONTAL;
}


#end