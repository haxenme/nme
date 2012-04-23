package nme.events;
#if code_completion


extern class FocusEvent extends Event {
	@:require(flash10) var isRelatedObjectInaccessible : Bool;
	var keyCode : UInt;
	var relatedObject : nme.display.InteractiveObject;
	var shiftKey : Bool;
	function new(type : String, bubbles : Bool = true, cancelable : Bool = false, ?relatedObject : nme.display.InteractiveObject, shiftKey : Bool = false, keyCode : UInt = 0) : Void;
	static var FOCUS_IN : String;
	static var FOCUS_OUT : String;
	static var KEY_FOCUS_CHANGE : String;
	static var MOUSE_FOCUS_CHANGE : String;
}


#elseif (cpp || neko)
typedef FocusEvent = neash.events.FocusEvent;
#elseif js
typedef FocusEvent = jeash.events.FocusEvent;
#else
typedef FocusEvent = flash.events.FocusEvent;
#end