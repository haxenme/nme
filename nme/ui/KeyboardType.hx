#if flash


package nme.ui;


@:native ("flash.ui.KeyboardType")
@:fakeEnum(String) extern enum KeyboardType {
	ALPHANUMERIC;
	KEYPAD;
	NONE;
}


#end