package nme.events;
#if code_completion


extern interface IEventDispatcher {
	function addEventListener(type : String, listener : Dynamic -> Void, useCapture : Bool = false, priority : Int = 0, useWeakReference : Bool = false) : Void;
	function dispatchEvent(event : Event) : Bool;
	function hasEventListener(type : String) : Bool;
	function removeEventListener(type : String, listener : Dynamic -> Void, useCapture : Bool = false) : Void;
	function willTrigger(type : String) : Bool;
}


#elseif (cpp || neko)
typedef IEventDispatcher = neash.events.IEventDispatcher;
#elseif js
typedef IEventDispatcher = jeash.events.IEventDispatcher;
#else
typedef IEventDispatcher = flash.events.IEventDispatcher;
#end
