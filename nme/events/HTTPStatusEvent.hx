package nme.events;
#if js

class HTTPStatusEvent extends Event 
{
	public var responseHeaders : Array<Dynamic>;
	public var responseURL : String;
	public var status(default,null) : Int;
	public function new(type : String, bubbles : Bool = false, cancelable : Bool = false, status : Int = 0) : Void 
	{
		this.status = status;
		super(type, bubbles, cancelable);
	}
	public static var HTTP_RESPONSE_STATUS : String;
	public static var HTTP_STATUS : String;
}

#else
typedef HTTPStatusEvent = flash.events.HTTPStatusEvent;
#end