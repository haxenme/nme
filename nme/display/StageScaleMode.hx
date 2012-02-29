package nme.display;

#if (cpp || neko)

typedef StageScaleMode = neash.display.StageScaleMode;

#elseif js

typedef StageScaleMode = jeash.display.StageScaleMode;

#else

typedef StageScaleMode = flash.display.StageScaleMode;

#end