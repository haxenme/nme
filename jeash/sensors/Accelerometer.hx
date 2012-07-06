package jeash.sensors;


import jeash.errors.ArgumentError;
import jeash.events.AccelerometerEvent;
import jeash.events.EventDispatcher;
import haxe.Timer;


class Accelerometer extends EventDispatcher
{
	
	public static var isSupported(nmeGetIsSupported, null):Bool;
	
	public var muted(default, setMuted):Bool;
	
	private static var defaultInterval:Int = 34;
	private var _interval:Int;
	
	/** @private */ private var timer:Timer;
	
	
	public function new() {
		super();
		_interval = 0;
		setRequestedUpdateInterval(defaultInterval);
	}

	private function setMuted(inVal:Bool):Bool {
		this.muted = inVal;
		setRequestedUpdateInterval(_interval);
		return inVal;
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
	
	/** @private */ private function update():Void {
		var event = new AccelerometerEvent(AccelerometerEvent.UPDATE);
		
		var data = jeash.display.Stage.jeashAcceleration;
		
		event.timestamp = Timer.stamp();
		event.accelerationX = data.x;
		event.accelerationY = data.y;
		event.accelerationZ = data.z;
		
		dispatchEvent(event);
	}

	/** @private */ private static function nmeGetIsSupported():Bool { 
		var supported = Reflect.hasField(js.Lib.window, "on" + Lib.HTML_ACCELEROMETER_EVENT_TYPE);
		return supported;
	}
}