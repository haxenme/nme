package nme.display;
#if code_completion


/**
 * The StageDisplayState class provides values for the
 * <code>Stage.displayState</code> property.
 */
@:fakeEnum(String) extern enum StageDisplayState {
	FULL_SCREEN;
	FULL_SCREEN_INTERACTIVE;

	/**
	 * Specifies that the Stage is in normal mode.
	 */
	NORMAL;
}


#elseif (cpp || neko)
typedef StageDisplayState = neash.display.StageDisplayState;
#elseif js
typedef StageDisplayState = jeash.display.StageDisplayState;
#else
typedef StageDisplayState = flash.display.StageDisplayState;
#end
