package nme.text;
#if code_completion


@:fakeEnum(String) extern enum TextFieldAutoSize {
	CENTER;
	LEFT;
	NONE;
	RIGHT;
}


#elseif (cpp || neko)
typedef TextFieldAutoSize = neash.text.TextFieldAutoSize;
#elseif js
typedef TextFieldAutoSize = jeash.text.TextFieldAutoSize;
#else
typedef TextFieldAutoSize = flash.text.TextFieldAutoSize;
#end