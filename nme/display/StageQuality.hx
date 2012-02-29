package nme.display;

#if (cpp || neko)

typedef StageQuality = neash.display.StageQuality;

#elseif js

typedef StageQuality = jeash.display.StageQuality;

#else

typedef StageQuality = flash.display.StageQuality;

#end