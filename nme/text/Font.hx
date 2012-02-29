package nme.text;

#if (cpp || neko)

typedef Font = neash.text.Font;

#elseif js

typedef Font = jeash.text.Font;

#else

typedef Font = flash.text.Font;

#end