package nme.events;
#if code_completion


extern class KeyboardEvent extends Event {
	var altKey : Bool;
	var charCode : Int;
	var ctrlKey : Bool;
	var keyCode : Int;
	//var keyLocation : nme.ui.KeyLocation;
	var shiftKey : Bool;
	//function new(type : String, bubbles : Bool = true, cancelable : Bool = false, charCodeValue : Int = 0, keyCodeValue : Int = 0, keyLocationValue : nme.ui.KeyLocation = 0, ctrlKeyValue : Bool = false, altKeyValue : Bool = false, shiftKeyValue : Bool = false) : Void;
	function new(type : String, bubbles : Bool = true, cancelable : Bool = false, charCodeValue : Int = 0, keyCodeValue : Int = 0) : Void;
	function updateAfterEvent() : Void;
	static var KEY_DOWN : String;
	static var KEY_UP : String;
}


#elseif (cpp || neko)
typedef KeyboardEvent = neash.events.KeyboardEvent;
#elseif js
typedef KeyboardEvent = jeash.events.KeyboardEvent;
#else
typedef KeyboardEvent = flash.events.KeyboardEvent;
#end