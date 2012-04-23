package nme.events;
#if code_completion


extern class TimerEvent extends Event {
	function new(type : String, bubbles : Bool = false, cancelable : Bool = false) : Void;
	function updateAfterEvent() : Void;
	static var TIMER : String;
	static var TIMER_COMPLETE : String;
}


#elseif (cpp || neko)
typedef TimerEvent = neash.events.TimerEvent;
#elseif js
typedef TimerEvent = jeash.events.TimerEvent;
#else
typedef TimerEvent = flash.events.TimerEvent;
#end