package nme.utils;
#if code_completion


extern class Timer extends nme.events.EventDispatcher {
	var currentCount(default,null) : Int;
	var delay : Float;
	var repeatCount : Int;
	var running(default,null) : Bool;
	function new(delay : Float, repeatCount : Int = 0) : Void;
	function reset() : Void;
	function start() : Void;
	function stop() : Void;
}


#elseif (cpp || neko)
typedef Timer = neash.utils.Timer;
#elseif js
typedef Timer = jeash.utils.Timer;
#else
typedef Timer = flash.utils.Timer;
#end