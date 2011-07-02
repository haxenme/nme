package nme.events;

class SecurityErrorEvent extends ErrorEvent
{
	public static inline var SECURITY_ERROR = "securityError";


   public function new(type:String, bubbles:Bool = false, cancelable:Bool = false, text:String = "", inID:Int=0)
   {
      super(type,bubbles,cancelable,text,inID);
   }
}

