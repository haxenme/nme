package nme.text;
#if (cpp || neko || js)


enum TextFieldType
{
	DYNAMIC;
	INPUT;
}


#else
typedef TextFieldType = flash.text.TextFieldType;
#end