package nme.text;
#if (cpp || neko || js)


enum FontType
{
	DEVICE;
	EMBEDDED;
	EMBEDDED_CFF;
}


#else
typedef FontType = flash.text.FontType;
#end