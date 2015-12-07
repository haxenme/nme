package nme.events;

#if (!flash)

@:nativeProperty
class NetStatusEvent extends Event
{
	public static inline var NET_STATUS = "netStatus";

	public var info : Dynamic;

	public function new(type : String, bubbles : Bool = false, cancelable : Bool = false, ? inInfo : Dynamic)
   {
      super(type,bubbles,cancelable);
      info = inInfo;
   }
}


#else
typedef NetStatusEvent = flash.events.NetStatusEvent;
#end

