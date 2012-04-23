package nme.events;
#if code_completion


@:require(flash10_1) extern class AccelerometerEvent extends Event {
	var accelerationX : Float;
	var accelerationY : Float;
	var accelerationZ : Float;
	var timestamp : Float;
	function new(type : String, bubbles : Bool = false, cancelable : Bool = false, timestamp : Float = 0, accelerationX : Float = 0, accelerationY : Float = 0, accelerationZ : Float = 0) : Void;
	static var UPDATE : String;
}


#elseif (cpp || neko)
typedef AccelerometerEvent = neash.events.AccelerometerEvent;
#elseif js
typedef AccelerometerEvent = jeash.events.AccelerometerEvent;
#else
typedef AccelerometerEvent = flash.events.AccelerometerEvent;
#end