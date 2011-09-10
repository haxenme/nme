#if flash


package nme.text;


@:native ("flash.text.TextFieldType")
@:fakeEnum(String) extern enum TextFieldType {
	DYNAMIC;
	INPUT;
}



#else


package nme.text;

enum TextFieldType
{
   DYNAMIC;
   INPUT;
}


#end