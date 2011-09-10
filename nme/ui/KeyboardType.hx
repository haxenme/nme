package nme.ui;


#if flash
@:native ("flash.ui.KeyboardType")
@:fakeEnum(String) extern enum KeyboardType {
	ALPHANUMERIC;
	KEYPAD;
	NONE;
}
#end