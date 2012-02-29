package nme.net;

#if (cpp || neko)

typedef URLLoaderDataFormat = neash.net.URLLoaderDataFormat;

#elseif js

typedef URLLoaderDataFormat = jeash.net.URLLoaderDataFormat;

#else

typedef URLLoaderDataFormat = flash.net.URLLoaderDataFormat;

#end