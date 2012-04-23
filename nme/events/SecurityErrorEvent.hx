package nme.events;
#if code_completion


extern class SecurityErrorEvent extends ErrorEvent {
	function new(type : String, bubbles : Bool = false, cancelable : Bool = false, ?text : String, id : Int = 0) : Void;
	static var SECURITY_ERROR : String;
}


#elseif (cpp || neko)
typedef SecurityErrorEvent = neash.events.SecurityErrorEvent;
#elseif js
typedef SecurityErrorEvent = jeash.events.SecurityErrorEvent;
#else
typedef SecurityErrorEvent = flash.events.SecurityErrorEvent;
#end