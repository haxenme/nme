package nme.text;


#if flash
@:native ("flash.text.TextFieldAutoSize")
@:fakeEnum(String) extern enum TextFieldAutoSize {
	CENTER;
	LEFT;
	NONE;
	RIGHT;
}
#else



enum TextFieldAutoSize
{
   CENTER;
   LEFT;
   NONE;
   RIGHT;
}
#end