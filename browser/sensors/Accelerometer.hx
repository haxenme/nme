package browser.sensors;
#if js


import browser.display.Stage;
import browser.errors.ArgumentError;
import browser.events.AccelerometerEvent;
import browser.events.EventDispatcher;
import haxe.Timer;
import js.Browser;


class Accelerometer extends EventDispatcher {
	
	
	public static var isSupported(get_isSupported, null):Bool;
	
	public var muted(default, set_muted):Bool;
	
	private var _interval:Int;
	private var timer:Timer;
	
	private static var defaultInterval:Int = 34;
	
	
	public function new() {
		
		super();
		
		_interval = 0;
		setRequestedUpdateInterval(defaultInterval);
		
	}
	
	
	override public function addEventListener(type:String, listener:Dynamic -> Void, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void {
		
		super.addEventListener(type, listener, useCapture, priority, useWeakReference);
		update();
		
	}
	
	
	public function setRequestedUpdateInterval(interval:Int):Void {
		
		_interval = interval;
		
		if (_interval < 0) {
			
			throw new ArgumentError();
			
		} else if (_interval == 0) {
			
			_interval = defaultInterval;
			
		}
		
		if (timer != null) {
			
			timer.stop();
			timer = null;
			
		}
		
		if (isSupported && !muted) {
			
			timer = new Timer(_interval);
			timer.run = update;
			
		}
		
	}
	
	
	private function update():Void {
		
		var event = new AccelerometerEvent(AccelerometerEvent.UPDATE);
		var data = Stage.nmeAcceleration;
		
		event.timestamp = Timer.stamp();
		event.accelerationX = data.x;
		event.accelerationY = data.y;
		event.accelerationZ = data.z;
		
		dispatchEvent(event);
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private static function get_isSupported():Bool { 
		
		var supported = Reflect.hasField(Browser.window, "on" + Lib.HTML_ACCELEROMETER_EVENT_TYPE);
		return supported;
		
	}
	
	
	private function set_muted(inVal:Bool):Bool {
		
		this.muted = inVal;
		setRequestedUpdateInterval(_interval);
		return inVal;
		
	}
	
	
}


#end
