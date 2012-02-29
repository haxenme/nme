package nme.display;

#if (cpp || neko)

typedef StageDisplayState = neash.display.StageDisplayState;

#elseif js

typedef StageDisplayState = jeash.display.StageDisplayState;

#else

typedef StageDisplayState = flash.display.StageDisplayState;

#end