package nme.ui;


#if flash
@:native ("flash.ui.MultitouchInputMode")
@:fakeEnum(String) extern enum MultitouchInputMode {
	GESTURE;
	NONE;
	TOUCH_POINT;
}
#else



enum MultitouchInputMode
{
   NONE;
   TOUCH_POINT;
   GESTURE;
}
#end