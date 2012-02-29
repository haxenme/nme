package nme.display;

#if (cpp || neko)

typedef LoaderInfo = neash.display.LoaderInfo;

#elseif js

typedef LoaderInfo = jeash.display.LoaderInfo;

#else

typedef LoaderInfo = flash.display.LoaderInfo;

#end