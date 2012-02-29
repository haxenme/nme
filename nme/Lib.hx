package nme;

#if (cpp || neko)

typedef Lib = neash.Lib;

#elseif js

typedef Lib = jeash.Lib;

#else

typedef Lib = flash.Lib;

#end