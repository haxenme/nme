package nme.events;
#if code_completion


extern class ProgressEvent extends Event {
	var bytesLoaded : Float;
	var bytesTotal : Float;
	function new(type : String, bubbles : Bool = false, cancelable : Bool = false, bytesLoaded : Float = 0, bytesTotal : Float = 0) : Void;
	static var PROGRESS : String;
	static var SOCKET_DATA : String;
}


#elseif (cpp || neko)
typedef ProgressEvent = neash.events.ProgressEvent;
#elseif js
typedef ProgressEvent = jeash.events.ProgressEvent;
#else
typedef ProgressEvent = flash.events.ProgressEvent;
#end