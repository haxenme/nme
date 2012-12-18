package native.utils;


import native.errors.Error;
import native.events.EventDispatcher;
import native.events.TimerEvent;


class Timer extends EventDispatcher {
	
	
	public var currentCount:Int;
	public var delay (get_delay, set_delay):Float;
	public var repeatCount:Int;
	public var running:Bool;
	
	/** @private */ private var _delay:Float;
	/** @private */ private var timer:haxe.Timer;
	
	
	public function new (delay:Float, repeatCount:Int = 0) {
		
		if (Math.isNaN (delay) || delay < 0) {
			
			throw new Error ("The delay specified is negative or not a finite number");
			
		}
		
		super ();
		
		_delay = delay;
		this.repeatCount = repeatCount;
		currentCount = 0;
		
	}
	
	
	public function reset () {
		
		if (running) {
			
			stop ();
			
		}
		
		currentCount = 0;
		
	}
	
	
	public function start () {
		
		if (!running) {
			
			running = true;
			timer = new haxe.Timer (_delay);
			timer.run = timer_onTimer;
			
		}
		
	}
	
	
	public function stop () {
		
		running = false;
		
		if (timer != null) {
			
			timer.stop ();
			timer = null;
			
		}
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function get_delay():Float {
		
		return _delay;
		
	}
	
	
	private function set_delay (value:Float):Float {
		
		_delay = value;
		
		if (running) {
			
			stop ();
			start ();
			
		}
		
		return _delay;
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	/** @private */ private function timer_onTimer ():Void {
		
		currentCount ++;
		
		if (repeatCount > 0 && currentCount >= repeatCount) {
			
			stop ();
			dispatchEvent (new TimerEvent (TimerEvent.TIMER));
			dispatchEvent (new TimerEvent (TimerEvent.TIMER_COMPLETE));
			
		} else {
			
			dispatchEvent (new TimerEvent (TimerEvent.TIMER));
			
		}
		
	}
	
	
}