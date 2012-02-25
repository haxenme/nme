package nme.events;
#if (cpp || neko)


class SecurityErrorEvent extends ErrorEvent
{
	
	public static inline var SECURITY_ERROR = "securityError";
	
	
	public function new(type:String, bubbles:Bool = false, cancelable:Bool = false, text:String = "", id:Int = 0)
	{
		super(type, bubbles, cancelable, text, id);
	}
	
	
	public override function clone ():Event
	{
		return new SecurityErrorEvent (type, bubbles, cancelable, text, errorID);
	}
	
	
	public override function toString ():String
	{
		return "[SecurityErrorEvent type=" + type + " bubbles=" + bubbles + " cancelable=" + cancelable + " text=" + text + " errorID=" + errorID + "]";
	}
	
}


#elseif js

class SecurityErrorEvent extends ErrorEvent {
	public function new(type : String, ?bubbles : Bool, ?cancelable : Bool, ?text : String) : Void
	{
		super(type, bubbles, cancelable);
		this.text = text;
	}
	static public var SECURITY_ERROR : String;
}

#else
typedef SecurityErrorEvent = flash.events.SecurityErrorEvent;
#end