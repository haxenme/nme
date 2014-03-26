package nme.events;

#if (cpp||neko)

class StageVideoEvent extends Event
{
	public static inline var RENDER_STATE = "renderState";
	public static inline var RENDER_STATUS_ACCELERATED = "accelerated";
	public static inline var RENDER_STATUS_SOFTWARE  = "software";
	public static inline var RENDER_STATUS_UNAVAILABLE  = "unavailable";
	//var codecInfo : String;
	public var colorSpace(default,null) : String;
	public var status(default,null) : String;

	function new(type : String, bubbles : Bool = false, cancelable : Bool = false, ?inStatus : String, ?inColorSpace : String) : Void
   {
      super(type,bubbles,cancelable);
      colorSpace = inColorSpace;
      status = inStatus;
   }
}

#else
typedef StageVideoEvent = flash.events.StageVideoEvent;
#end
