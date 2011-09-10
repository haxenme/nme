package nme.ui;


#if flash
@:native ("flash.ui.KeyLocation")
@:fakeEnum(UInt) extern enum KeyLocation {
	D_PAD;
	LEFT;
	NUM_PAD;
	RIGHT;
	STANDARD;
}
#end