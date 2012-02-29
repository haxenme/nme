package nme.text;

#if (cpp || neko)

typedef TextField = neash.text.TextField;

#elseif js

typedef TextField = jeash.text.TextField;

#else

typedef TextField = flash.text.TextField;

#end