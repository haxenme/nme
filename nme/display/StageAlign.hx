package nme.display;

#if (cpp || neko)

typedef StageAlign = neash.display.StageAlign;

#elseif js

typedef StageAlign = jeash.display.StageAlign;

#else

typedef StageAlign = flash.display.StageAlign;

#end