#if flash


package nme.net;


@:native ("flash.net.URLLoaderDataFormat")
@:fakeEnum(String) extern enum URLLoaderDataFormat {
	BINARY;
	TEXT;
	VARIABLES;
}


#else



package nme.net;

enum URLLoaderDataFormat
{
   BINARY;
   TEXT;
   VARIABLES;
}


#end