package nme.events;
#if (cpp || neko)


class ErrorEvent extends TextEvent
{

	public var errorID(default, null):Int;
	
	
	public function new(type:String, bubbles:Bool = false, cancelable:Bool = false, text:String = "", id:Int = 0)
	{
		super(type, bubbles, cancelable, text);
		errorID = id;
	}
	
	
	public override function clone ():Event
	{
		return new ErrorEvent (type, bubbles, cancelable, text, errorID);
	}
	
	
	public override function toString ():String
	{
		return "[ErrorEvent type=" + type + " bubbles=" + bubbles + " cancelable=" + cancelable + " text=" + text + " errorID=" + errorID + "]";
	}
	
}


#elseif js

class ErrorEvent extends TextEvent {
	public function new(type : String, ?bubbles : Bool, ?cancelable : Bool, ?text : String) : Void
	{
		super(type, bubbles, cancelable);
		this.text = text;
	}
	public static var ERROR : String = "nme.events.ErrorEvent";
}

#else
typedef ErrorEvent = flash.events.ErrorEvent;
#end