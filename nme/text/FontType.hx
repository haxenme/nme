package nme.text;
#if (cpp || neko)


@:fakeEnum(String) extern enum FontType {
	DEVICE;
	EMBEDDED;
	EMBEDDED_CFF;
}


#else
typedef FontType = flash.text.FontType;
#end