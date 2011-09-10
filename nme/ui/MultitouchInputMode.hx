#if flash


package nme.ui;


@:native ("flash.ui.MultitouchInputMode")
@:fakeEnum(String) extern enum MultitouchInputMode {
	GESTURE;
	NONE;
	TOUCH_POINT;
}



#else


package nme.ui;

enum MultitouchInputMode
{
   NONE;
   TOUCH_POINT;
   GESTURE;
}


#end