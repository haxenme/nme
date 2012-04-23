package nme.net;
#if code_completion


extern class URLRequestMethod {
	@:require(flash10_1) static var DELETE : String;
	static var GET : String;
	@:require(flash10_1) static var HEAD : String;
	@:require(flash10_1) static var OPTIONS : String;
	static var POST : String;
	@:require(flash10_1) static var PUT : String;
}


#elseif (cpp || neko)
typedef URLRequestMethod = neash.net.URLRequestMethod;
#elseif js
typedef URLRequestMethod = jeash.net.URLRequestMethod;
#else
typedef URLRequestMethod = flash.net.URLRequestMethod;
#end