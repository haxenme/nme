package nme.net;

#if (cpp || neko)

typedef URLLoader = neash.net.URLLoader;

#elseif js

typedef URLLoader = jeash.net.URLLoader;

#else

typedef URLLoader = flash.net.URLLoader;

#end