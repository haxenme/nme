package browser.utils;
#if js


import browser.events.EventDispatcher;
import browser.events.TimerEvent;


class Timer extends EventDispatcher {
	
	
	public var currentCount(default, null):Int;
	public var delay(default, set_delay):Float;
	public var repeatCount(default, set_repeatCount):Int;
	public var running(default, null):Bool;

	private var timerId:Int;
	

	public function new(delay:Float, repeatCount:Int = 0):Void {
		
		super();
		
		this.running = false;
		this.delay = delay;
		this.repeatCount = repeatCount;
		this.currentCount = 0;
		
	}
	
	
	public function reset():Void {
		
		stop();
		currentCount = 0;
		
	}
	
	
	public function start():Void {
		
		if (running) return;
		
		running = true;
		timerId = untyped window.setTimeout(__onInterval, Std.int(delay));
		
	}
	
	
	public function stop():Void {
		
		if (timerId != null) {
			
			untyped window.clearTimeout(timerId);
			timerId = null;
			
		}
		
		running = false;
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private function __onInterval():Void {
		
		var evtCom:TimerEvent = null;
		
		if (repeatCount != 0 && ++currentCount >= repeatCount) {
			
			stop();
			evtCom = new TimerEvent(TimerEvent.TIMER_COMPLETE);
			evtCom.target = this;
			
		}
		
		var evt = new TimerEvent(TimerEvent.TIMER);
		evt.target = this;
		dispatchEvent(evt);
		
		// dispatch complete if necessary
		if (evtCom != null) {
			
			dispatchEvent(evtCom);
			
		}
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function set_delay(v:Float):Float {
		
		if (v != delay) {
			
			var wasRunning = running;
			
			if (running) stop();
			
			this.delay = v;
			
			if (wasRunning) start();
			
		}
		
		return v;
		
	}
	
	
	private function set_repeatCount(v:Int):Int {
		
		if (running && v != 0 && v <= currentCount) {
			
			stop();
			
		}
		
		repeatCount = v;
		return v;
		
	}
	
	
}


#end