package nme.text;

#if (cpp || neko)

typedef FontStyle = neash.text.FontStyle;

#elseif js

typedef FontStyle = jeash.text.FontStyle;

#else

typedef FontStyle = flash.text.FontStyle;

#end