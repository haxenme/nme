package nme.events;
#if js

class NetStatusEvent extends Event {
	public var info : Dynamic;
	public function new(type : String, ?bubbles : Bool, ?cancelable : Bool, ?info : Dynamic) : Void
	{
		this.info = info;
		super(type,bubbles,cancelable);
	}
	public static var NET_STATUS : String = "nme.net.NetStatusEvent";
}
#else
typedef NetStatusEvent = flash.events.NetStatusEvent;
#end