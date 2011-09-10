package nme.text;


#if flash
@:native ("flash.text.TextFieldType")
@:fakeEnum(String) extern enum TextFieldType {
	DYNAMIC;
	INPUT;
}
#else



enum TextFieldType
{
   DYNAMIC;
   INPUT;
}
#end