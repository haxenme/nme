package nme.events;
#if code_completion


extern class TextEvent extends Event {
	var text : String;
	function new(type : String, bubbles : Bool = false, cancelable : Bool = false, ?text : String) : Void;
	static var LINK : String;
	static var TEXT_INPUT : String;
}


#elseif (cpp || neko)
typedef TextEvent = neash.events.TextEvent;
#elseif js
typedef TextEvent = jeash.events.TextEvent;
#else
typedef TextEvent = flash.events.TextEvent;
#end