package nme2.events;
import nme2.events.IEventDispatcher;
import nme2.events.Event;


class EventDispatcher implements IEventDispatcher
{
	public function addEventListener(type:String, listener:Function,
	         useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void
	{
	}

	public function dispatchEvent(event:Event):Bool
	{
	   return false;
	}
	public function hasEventListener(type:String):Bool
	{
	   return false;
	}
	public function removeEventListener(type:String, listener:Function, useCapture:Bool= false):Void
	{
	}
	public function willTrigger(type:String):Bool
	{
	   return false;
	}
}
