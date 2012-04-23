package nme.net;
#if code_completion


extern class URLVariables implements Dynamic {
	function new(?source : String) : Void;
	function decode(source : String) : Void;
	function toString() : String;
}


#elseif (cpp || neko)
typedef URLVariables = neash.net.URLVariables;
#elseif js
typedef URLVariables = jeash.net.URLVariables;
#else
typedef URLVariables = flash.net.URLVariables;
#end