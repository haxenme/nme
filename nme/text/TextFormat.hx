package nme.text;

#if (cpp || neko)

typedef TextFormat = neash.text.TextFormat;

#elseif js

typedef TextFormat = jeash.text.TextFormat;

#else

typedef TextFormat = flash.text.TextFormat;

#end