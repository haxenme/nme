package nme.text;
#if code_completion


@:fakeEnum(String) extern enum TextFieldType {
	DYNAMIC;
	INPUT;
}


#elseif (cpp || neko)
typedef TextFieldType = neash.text.TextFieldType;
#elseif js
typedef TextFieldType = jeash.text.TextFieldType;
#else
typedef TextFieldType = flash.text.TextFieldType;
#end