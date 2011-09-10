#if flash


package nme.sensors;


@:native ("flash.sensors.Geolocation")
@:require(flash10_1) extern class Geolocation extends nme.events.EventDispatcher {
	var muted(default,null) : Bool;
	function new() : Void;
	function setRequestedUpdateInterval(interval : Float) : Void;
	static var isSupported(default,null) : Bool;
}



#end