package nme.events;
#if (cpp || neko)


class TextEvent extends Event
{
	
	public static var LINK:String = "link";
	public static var TEXT_INPUT:String = "textInput";
	
	public var text(default, null):String;
	
	
	public function new(type:String, bubbles:Bool = false, cancelable:Bool = false, text:String = "")
	{
		super(type, bubbles, cancelable);
		this.text = text;
	}
	
	
	public override function clone ():Event
	{
		return new TextEvent (type, bubbles, cancelable, text);
	}
	
	
	public override function toString ():String
	{
		return "[TextEvent type=" + type + " bubbles=" + bubbles + " cancelable=" + cancelable + " text=" + text + "]";
	}
	
}


#elseif js

class TextEvent extends Event {
	public var text : String;
	function new(type : String, ?bubbles : Bool, ?cancelable : Bool, ?text : String) 
	{
		super(type, bubbles, cancelable);
		this.text = text;
	}
	static var LINK : String;
	static var TEXT_INPUT : String;
}

#else
typedef TextEvent = flash.events.TextEvent;
#end