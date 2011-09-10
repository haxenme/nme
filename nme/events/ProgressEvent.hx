package nme.events;


#if flash
@:native ("flash.events.ProgressEvent")
extern class ProgressEvent extends Event {
	var bytesLoaded : Float;
	var bytesTotal : Float;
	function new(type : String, bubbles : Bool = false, cancelable : Bool = false, bytesLoaded : Float = 0, bytesTotal : Float = 0) : Void;
	static var PROGRESS : String;
	static var SOCKET_DATA : String;
}
#else



class ProgressEvent extends Event
{
   public static inline var PROGRESS = "progress";
   public static inline var SOCKET_DATA = "socketData";

   public var bytesTotal(default,null):Int;
   public var bytesLoaded(default,null):Int;

	public function new(type:String, bubbles:Bool = false, cancelable:Bool = false, inBytesLoaded:Int = 0, inBytesTotal:Int = 0)
	{
	   super(type,bubbles,cancelable);
		bytesLoaded = inBytesLoaded;
		bytesTotal = inBytesTotal;
	}

}
#end