package nme.net;
#if code_completion


extern class URLLoader extends nme.events.EventDispatcher {
	var bytesLoaded : Int;
	var bytesTotal : Int;
	var data : Dynamic;
	var dataFormat : URLLoaderDataFormat;
	function new(?request : URLRequest) : Void;
	function close() : Void;
	function load(request : URLRequest) : Void;
}


#elseif (cpp || neko)
typedef URLLoader = neash.net.URLLoader;
#elseif js
typedef URLLoader = jeash.net.URLLoader;
#else
typedef URLLoader = flash.net.URLLoader;
#end