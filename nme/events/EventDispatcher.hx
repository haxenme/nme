package nme.events;
#if code_completion


extern class EventDispatcher implements IEventDispatcher {
	function new(?target : IEventDispatcher) : Void;
	function addEventListener(type : String, listener : Dynamic -> Void, useCapture : Bool = false, priority : Int = 0, useWeakReference : Bool = false) : Void;
	function dispatchEvent(event : Event) : Bool;
	function hasEventListener(type : String) : Bool;
	function removeEventListener(type : String, listener : Dynamic -> Void, useCapture : Bool = false) : Void;
	function toString() : String;
	function willTrigger(type : String) : Bool;
}


#elseif (cpp || neko)
typedef EventDispatcher = neash.events.EventDispatcher;
#elseif js
typedef EventDispatcher = jeash.events.EventDispatcher;
#else
typedef EventDispatcher = flash.events.EventDispatcher;
#end