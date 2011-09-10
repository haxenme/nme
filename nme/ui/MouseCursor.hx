package nme.ui;


#if flash
@:native ("flash.ui.MouseCursor")
@:fakeEnum(String) extern enum MouseCursor {
	ARROW;
	AUTO;
	BUTTON;
	HAND;
	IBEAM;
}
#end