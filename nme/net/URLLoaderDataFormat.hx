package nme.net;
#if cpp || neko


enum URLLoaderDataFormat
{
   BINARY;
   TEXT;
   VARIABLES;
}


#else
typedef URLLoaderDataFormat = flash.net.URLLoaderDataFormat;
#end