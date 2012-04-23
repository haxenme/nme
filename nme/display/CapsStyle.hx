package nme.display;
#if code_completion


@:fakeEnum(String) extern enum CapsStyle {
	NONE;
	ROUND;
	SQUARE;
}


#elseif (cpp || neko)
typedef CapsStyle = neash.display.CapsStyle;
#elseif js
typedef CapsStyle = jeash.display.CapsStyle;
#else
typedef CapsStyle = flash.display.CapsStyle;
#end