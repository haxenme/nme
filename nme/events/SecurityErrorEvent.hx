#if flash


package nme.events;


@:native ("flash.events.SecurityErrorEvent")
extern class SecurityErrorEvent extends ErrorEvent {
	function new(type : String, bubbles : Bool = false, cancelable : Bool = false, ?text : String, id : Int = 0) : Void;
	static var SECURITY_ERROR : String;
}



#else


package nme.events;

class SecurityErrorEvent extends ErrorEvent
{
	public static inline var SECURITY_ERROR = "securityError";


   public function new(type:String, bubbles:Bool = false, cancelable:Bool = false, text:String = "", inID:Int=0)
   {
      super(type,bubbles,cancelable,text,inID);
   }
}


#end