package nme.text;
#if code_completion


@:fakeEnum(String) extern enum FontStyle {
	BOLD;
	BOLD_ITALIC;
	ITALIC;
	REGULAR;
}


#elseif (cpp || neko)
typedef FontStyle = neash.text.FontStyle;
#elseif js
typedef FontStyle = jeash.text.FontStyle;
#else
typedef FontStyle = flash.text.FontStyle;
#end