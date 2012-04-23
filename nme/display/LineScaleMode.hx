package nme.display;
#if code_completion


@:fakeEnum(String) extern enum LineScaleMode {
	HORIZONTAL;
	NONE;
	NORMAL;
	VERTICAL;
}


#elseif (cpp || neko)
typedef LineScaleMode = neash.display.LineScaleMode;
#elseif js
typedef LineScaleMode = jeash.display.LineScaleMode;
#else
typedef LineScaleMode = flash.display.LineScaleMode;
#end