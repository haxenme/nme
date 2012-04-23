package nme.display;
#if code_completion


@:fakeEnum(String) extern enum StageQuality {
	BEST;
	HIGH;
	LOW;
	MEDIUM;
}


#elseif (cpp || neko)
typedef StageQuality = neash.display.StageQuality;
#elseif js
typedef StageQuality = jeash.display.StageQuality;
#else
typedef StageQuality = flash.display.StageQuality;
#end