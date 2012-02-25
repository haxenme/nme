package nme.events;
#if (cpp || neko)


class TimerEvent extends Event
{
	
	public static var TIMER:String = "timer";
	public static var TIMER_COMPLETE:String = "timerComplete";
	
	
	public function new(type:String, bubbles:Bool = false, cancelable:Bool = false)
	{
		super(type, bubbles, cancelable);
	}
	
	
	public override function clone ():Event
	{
		return new TimerEvent (type, bubbles, cancelable);
	}
	
	
	public override function toString ():String
	{
		return "[TimerEvent type=" + type + " bubbles=" + bubbles + " cancelable=" + cancelable + "]";
	}
	
	
	public function updateAfterEvent()
	{
		
	}
	
}


#elseif js

import nme.events.Event;

class TimerEvent extends Event {
	public function new(type : String, ?bubbles : Bool, ?cancelable : Bool) : Void {
      super(type,bubbles,cancelable);
	}

	public function updateAfterEvent() : Void {
	}

	public static inline var TIMER : String = "timer";
	public static inline var TIMER_COMPLETE : String = "timerComplete";
}

#else
typedef TimerEvent = flash.events.TimerEvent;
#end