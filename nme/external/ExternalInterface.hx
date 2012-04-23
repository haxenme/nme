package nme.events;
#if code_completion


extern class ExternalInterface {
	static var available(default,null) : Bool;
	static var marshallExceptions : Bool;
	static var objectID(default,null) : String;
	static function addCallback(functionName : String, closure : Dynamic) : Void;
	static function call(functionName : String, ?p1 : Dynamic, ?p2 : Dynamic, ?p3 : Dynamic, ?p4 : Dynamic, ?p5 : Dynamic) : Dynamic;
}


#elseif (cpp || neko)
typedef ExternalInterface = neash.events.ExternalInterface;
#elseif js
typedef ExternalInterface = jeash.events.ExternalInterface;
#else
typedef ExternalInterface = flash.events.ExternalInterface;
#end