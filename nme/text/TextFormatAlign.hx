package nme.text;
#if code_completion


@:fakeEnum(String) extern enum TextFormatAlign {
	CENTER;
	JUSTIFY;
	LEFT;
	RIGHT;
}


#elseif (cpp || neko)
typedef TextFormatAlign = neash.text.TextFormatAlign;
#elseif js
typedef TextFormatAlign = jeash.text.TextFormatAlign;
#else
typedef TextFormatAlign = flash.text.TextFormatAlign;
#end