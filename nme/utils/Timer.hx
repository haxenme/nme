package nme.utils;
#if (cpp || neko)


import nme.errors.Error;
import nme.events.EventDispatcher;
import nme.events.TimerEvent;


class Timer extends EventDispatcher
{
	
	public var currentCount:Int;
	public var delay:Float;
	public var repeatCount:Int;
	public var running:Bool;
	
	private var timer:haxe.Timer;
	
	
	public function new(delay:Float, repeatCount:Int = 0)
	{
		if (Math.isNaN (delay) || delay < 0)
		{
			throw new Error ("The delay specified is negative or not a finite number");
		}
		
		super ();
		
		this.delay = delay;
		this.repeatCount = repeatCount;
		currentCount = 0;
	}
	
	
	public function reset()
	{
		if (running)
		{
			stop ();
		}
		currentCount = 0;
	}
	
	
	public function start()
	{
		if (!running)
		{
			running = true;
			timer = new haxe.Timer (delay);
			timer.run = timer_onTimer;
		}
	}
	
	
	public function stop()
	{
		running = false;
		
		if (timer != null)
		{
			timer.stop();
			timer = null;
		}
	}
	
	
	
	// Event Handlers
	
	
	
	private function timer_onTimer ():Void
	{
		currentCount ++;
		
		if (repeatCount > 0 && currentCount >= repeatCount)
		{
			stop ();
			dispatchEvent (new TimerEvent (TimerEvent.TIMER));
			dispatchEvent (new TimerEvent (TimerEvent.TIMER_COMPLETE));
		}
		else
		{
			dispatchEvent (new TimerEvent (TimerEvent.TIMER));
		}
	}
	
}


#elseif js

import nme.events.EventDispatcher;
import nme.events.TimerEvent;

/**
* @author Niel Drummond
* @author Russell Weir
**/
class Timer extends EventDispatcher {
	public var currentCount(default,null) : Int;
	public var delay(default,__setDelay) : Float;
	public var repeatCount(default,__setRepeatCount) : Int;
	public var running(default,null) : Bool;

	var timerId : Int;

	public function new(delay : Float, repeatCount : Int=0) : Void {
		super();
		this.running = false;
		this.delay = delay;
		this.repeatCount = repeatCount;
		this.currentCount = 0;
	}

	public function reset() : Void {
		stop();
		currentCount = 0;
	}

	public function start() : Void {
		if(running)
			return;
		running = true;
		
		timerId = untyped window.setTimeout(__onInterval, Std.int(delay));
	}

	public function stop() : Void {
		if (timerId != null) {
			untyped window.clearTimeout(timerId);
			timerId = null;
		}
		running = false;
	}

	private function __onInterval() : Void
	{
		var evtCom : TimerEvent = null;

		if( repeatCount != 0 && ++currentCount >= repeatCount ) {
			stop();
			evtCom = new TimerEvent(TimerEvent.TIMER_COMPLETE);
			evtCom.target = this;
		}

		var evt = new TimerEvent(TimerEvent.TIMER);
		evt.target = this;
		dispatchEvent(evt);
		// dispatch complete if necessary
		if(evtCom != null)
			dispatchEvent(evtCom);
	}

	private function __setDelay(v:Float) : Float
	{
		if(v != delay) {
			var wasRunning = running;
			if(running)
				stop();
			this.delay = v;
			if(wasRunning)
				start();
		}
		return v;
	}

	private function __setRepeatCount(v : Int ) : Int
	{
		if(running && v != 0 && v <= currentCount)
			stop();
		repeatCount = v;
		return v;
	}
}

#else
typedef Timer = flash.utils.Timer;
#end