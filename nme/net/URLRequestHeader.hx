package nme.net;
#if code_completion


@:final extern class URLRequestHeader {
	var name : String;
	var value : String;
	function new(?name : String, ?value : String):Void;
}


//#elseif (cpp || neko)
//typedef URLRequestHeader = neash.net.URLRequestHeader;
#elseif js
typedef URLRequestHeader = jeash.net.URLRequestHeader;
#else
typedef URLRequestHeader = flash.net.URLRequestHeader;
#end