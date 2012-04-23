package nme.sensors;
#if code_completion


@:require(flash10_1) extern class Accelerometer extends nme.events.EventDispatcher {
	var muted(default,null) : Bool;
	function new() : Void;
	function setRequestedUpdateInterval(interval : Float) : Void;
	static var isSupported(default,null) : Bool;
}


#elseif (cpp || neko)
typedef Accelerometer = neash.sensors.Accelerometer;
#elseif js
typedef Accelerometer = jeash.sensors.Accelerometer;
#else
typedef Accelerometer = flash.sensors.Accelerometer;
#end