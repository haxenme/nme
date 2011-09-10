package nme.net;


#if flash
@:native ("flash.net.URLRequestHeader")
@:final extern class URLRequestHeader {
	var name : String;
	var value : String;
	function new(?name : String, ?value : String) : Void;
}
#end