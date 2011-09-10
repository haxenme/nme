#if flash


package nme.text;


@:native ("flash.text.TextFieldAutoSize")
@:fakeEnum(String) extern enum TextFieldAutoSize {
	CENTER;
	LEFT;
	NONE;
	RIGHT;
}



#else


package nme.text;

enum TextFieldAutoSize
{
   CENTER;
   LEFT;
   NONE;
   RIGHT;
}



#end