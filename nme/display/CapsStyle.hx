package nme.display;

#if (cpp || neko)

typedef CapsStyle = neash.display.CapsStyle;

#elseif js

typedef CapsStyle = jeash.display.CapsStyle;

#else

typedef CapsStyle = flash.display.CapsStyle;

#end