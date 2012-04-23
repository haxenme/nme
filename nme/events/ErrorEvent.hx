package nme.events;
#if code_completion


extern class ErrorEvent extends TextEvent {
	@:require(flash10_1) var errorID(default,null) : Int;
	function new(type : String, bubbles : Bool = false, cancelable : Bool = false, ?text : String, id : Int = 0) : Void;
	static var ERROR : String;
}


#elseif (cpp || neko)
typedef ErrorEvent = neash.events.ErrorEvent;
#elseif js
typedef ErrorEvent = jeash.events.ErrorEvent;
#else
typedef ErrorEvent = flash.events.ErrorEvent;
#end