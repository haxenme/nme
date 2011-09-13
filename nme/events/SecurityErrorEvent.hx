package nme.events;
#if cpp || neko


class SecurityErrorEvent extends ErrorEvent
{
	public static inline var SECURITY_ERROR = "securityError";


   public function new(type:String, bubbles:Bool = false, cancelable:Bool = false, text:String = "", inID:Int=0)
   {
      super(type,bubbles,cancelable,text,inID);
   }
}


#else
typedef SecurityErrorEvent = flash.events.SecurityErrorEvent;
#end