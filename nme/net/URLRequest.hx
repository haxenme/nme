package nme.net;
#if code_completion


@:final extern class URLRequest {
	var contentType : String;
	var data : Dynamic;
	var digest : String;
	var method : String;
	//var requestHeaders : Array<URLRequestHeader>;
	var url : String;
	function new(?url : String) : Void;
}


#elseif (cpp || neko)
typedef URLRequest = neash.net.URLRequest;
#elseif js
typedef URLRequest = jeash.net.URLRequest;
#else
typedef URLRequest = flash.net.URLRequest;
#end