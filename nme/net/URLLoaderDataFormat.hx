package nme.net;
#if code_completion


@:fakeEnum(String) extern enum URLLoaderDataFormat {
	BINARY;
	TEXT;
	VARIABLES;
}


#elseif (cpp || neko)
typedef URLLoaderDataFormat = neash.net.URLLoaderDataFormat;
#elseif js
typedef URLLoaderDataFormat = jeash.net.URLLoaderDataFormat;
#else
typedef URLLoaderDataFormat = flash.net.URLLoaderDataFormat;
#end