package nme.net;


#if flash
@:native ("flash.net.URLLoaderDataFormat")
@:fakeEnum(String) extern enum URLLoaderDataFormat {
	BINARY;
	TEXT;
	VARIABLES;
}
#else



enum URLLoaderDataFormat
{
   BINARY;
   TEXT;
   VARIABLES;
}
#end