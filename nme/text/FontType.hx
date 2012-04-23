package nme.text;
#if code_completion


@:fakeEnum(String) extern enum FontType {
	DEVICE;
	EMBEDDED;
	EMBEDDED_CFF;
}


#elseif (cpp || neko)
typedef FontType = neash.text.FontType;
#elseif js
typedef FontType = jeash.text.FontType;
#else
typedef FontType = flash.text.FontType;
#end