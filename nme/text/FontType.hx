package nme.text;


#if flash
@:native ("flash.text.FontType")
@:fakeEnum(String) extern enum FontType {
	DEVICE;
	EMBEDDED;
	EMBEDDED_CFF;
}
#else



@:fakeEnum(String) extern enum FontType {
	DEVICE;
	EMBEDDED;
	EMBEDDED_CFF;
}
#end