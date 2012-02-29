package nme.text;

#if (cpp || neko)

typedef FontType = neash.text.FontType;

#elseif js

typedef FontType = jeash.text.FontType;

#else

typedef FontType = flash.text.FontType;

#end