package nme.sensors;
#if cpp || neko


import nme.events.AccelerometerEvent;
import nme.events.EventDispatcher;
import nme.Timer;


class Accelerometer extends EventDispatcher {
	
	
	public static var isSupported (default, null):Bool;
	
	public var muted (default, null):Bool;
	
	private var timer:Timer;
	
	
	public function new () {
		
		super ();
		
		if (nme_input_get_acceleration () == null) {
			
			isSupported = false;
			
		} else {
			
			isSupported = true;
			
		}
		
	}
	
	
	public function setRequestedUpdateInterval (interval:Float):Void {
		
		if (timer != null) {
			
			timer.stop ();
			
		}
		
		timer = new Timer (interval);
		timer.run = update;
		
	}
	
	
	private function update ():Void {
		
		var event = new AccelerometerEvent (AccelerometerEvent.UPDATE);
		
		var data = nme_input_get_acceleration ();
		
		event.timestamp = Timer.stamp ();
		event.accelerationX = data.x;
		event.accelerationY = data.y;
		event.accelerationZ = data.z;
		
		dispatchEvent (event);
		
	}
	
	
	static var nme_input_get_acceleration = nme.Loader.load("nme_input_get_acceleration",0);
	
	
}


#else
typedef Accelerometer = flash.sensors.Accelerometer;
#end