package nme.text;

#if (cpp || neko)

typedef TextFieldType = neash.text.TextFieldType;

#elseif js

typedef TextFieldType = jeash.text.TextFieldType;

#else

typedef TextFieldType = flash.text.TextFieldType;

#end