package nme.net;
#if (cpp || neko || js)


enum URLLoaderDataFormat
{
	BINARY;
	TEXT;
	VARIABLES;
}


#else
typedef URLLoaderDataFormat = flash.net.URLLoaderDataFormat;
#end