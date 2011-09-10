package nme.utils;


#if flash
@:native ("flash.utils.Namespace")
@:final extern class Namespace {
	var prefix(default,null) : Dynamic;
	var uri(default,null) : String;
	function new(?prefix : Dynamic, ?uri : Dynamic) : Void;
}
#end