package nme.display;
#if cpp || neko


enum StageScaleMode { SHOW_ALL; NO_SCALE; NO_BORDER; EXACT_FIT; }


#else
typedef StageScaleMode = flash.display.StageScaleMode;
#end