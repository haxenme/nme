package nme.display;

#if (cpp || neko)

typedef Loader = neash.display.Loader;

#elseif js

typedef Loader = jeash.display.Loader;

#else

typedef Loader = flash.display.Loader;

#end