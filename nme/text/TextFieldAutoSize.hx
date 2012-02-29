package nme.text;

#if (cpp || neko)

typedef TextFieldAutoSize = neash.text.TextFieldAutoSize;

#elseif js

typedef TextFieldAutoSize = jeash.text.TextFieldAutoSize;

#else

typedef TextFieldAutoSize = flash.text.TextFieldAutoSize;

#end