package nme.events;
#if (cpp || neko)


class ProgressEvent extends Event
{
	
	public static inline var PROGRESS = "progress";
	public static inline var SOCKET_DATA = "socketData";

	public var bytesLoaded(default, null):Int;
	public var bytesTotal(default, null):Int;
	
	
	public function new(type:String, bubbles:Bool = false, cancelable:Bool = false, inBytesLoaded:Int = 0, inBytesTotal:Int = 0)
	{
		super(type, bubbles, cancelable);
		bytesLoaded = inBytesLoaded;
		bytesTotal = inBytesTotal;
	}
	
}


#else
typedef ProgressEvent = flash.events.ProgressEvent;
#end