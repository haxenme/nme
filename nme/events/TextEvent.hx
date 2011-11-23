package nme.events;
#if (cpp || neko)


class TextEvent extends Event
{
	
	public var text(default, null):String;
	
	
	public function new(type:String, bubbles:Bool = false, cancelable:Bool = false, inText:String = "")
	{
		super(type, bubbles, cancelable);
		text = inText;
	}
	
}


#else
typedef TextEvent = flash.events.TextEvent;
#end