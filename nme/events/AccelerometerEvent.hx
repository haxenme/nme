package nme.events;
#if (cpp || neko)


import nme.events.Event;


class AccelerometerEvent extends Event {
	
	
	public static var UPDATE : String;
	
	public var accelerationX : Float;
	public var accelerationY : Float;
	public var accelerationZ : Float;
	public var timestamp : Float;
	
	
	public function new (type : String, bubbles : Bool = false, cancelable : Bool = false, timestamp : Float = 0, accelerationX : Float = 0, accelerationY : Float = 0, accelerationZ : Float = 0) : Void {
		
		super (type, bubbles, cancelable);
		
		this.timestamp = timestamp;
		this.accelerationX = accelerationX;
		this.accelerationY = accelerationY;
		this.accelerationZ = accelerationZ;
		
	}
	
	
}


#else
typedef AccelerometerEvent = flash.events.AccelerometerEvent;
#end