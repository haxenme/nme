package nme.display;
#if display


/**
 * The StageScaleMode class provides values for the
 * <code>Stage.scaleMode</code> property.
 */
@:fakeEnum(String) extern enum StageScaleMode {
	EXACT_FIT;
	NO_BORDER;
	NO_SCALE;
	SHOW_ALL;
}


#elseif (cpp || neko)
typedef StageScaleMode = native.display.StageScaleMode;
#elseif js
typedef StageScaleMode = browser.display.StageScaleMode;
#else
typedef StageScaleMode = flash.display.StageScaleMode;
#end
