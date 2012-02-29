package nme.display;

#if (cpp || neko)

typedef SpreadMethod = neash.display.SpreadMethod;

#elseif js

typedef SpreadMethod = jeash.display.SpreadMethod;

#else

typedef SpreadMethod = flash.display.SpreadMethod;

#end