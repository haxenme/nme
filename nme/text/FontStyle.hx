package nme.text;
#if (cpp || neko || js)


enum FontStyle
{
	REGULAR;
	ITALIC;
	BOLD_ITALIC;
	BOLD;
}


#else
typedef FontStyle = flash.text.FontStyle;
#end