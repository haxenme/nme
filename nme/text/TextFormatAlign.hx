package nme.text;

#if (cpp || neko)

typedef TextFormatAlign = neash.text.TextFormatAlign;

#elseif js

typedef TextFormatAlign = jeash.text.TextFormatAlign;

#else

typedef TextFormatAlign = flash.text.TextFormatAlign;

#end