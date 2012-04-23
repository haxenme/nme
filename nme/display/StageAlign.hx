package nme.display;
#if code_completion


@:fakeEnum(String) extern enum StageAlign {
	BOTTOM;
	BOTTOM_LEFT;
	BOTTOM_RIGHT;
	LEFT;
	RIGHT;
	TOP;
	TOP_LEFT;
	TOP_RIGHT;
}


#elseif (cpp || neko)
typedef StageAlign = neash.display.StageAlign;
#elseif js
typedef StageAlign = jeash.display.StageAlign;
#else
typedef StageAlign = flash.display.StageAlign;
#end