package nme.display;
#if code_completion


@:fakeEnum(String) extern enum StageDisplayState {
	FULL_SCREEN;
	FULL_SCREEN_INTERACTIVE;
	NORMAL;
}


#elseif (cpp || neko)
typedef StageDisplayState = neash.display.StageDisplayState;
#elseif js
typedef StageDisplayState = jeash.display.StageDisplayState;
#else
typedef StageDisplayState = flash.display.StageDisplayState;
#end