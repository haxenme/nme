#if flash


package nme.events;


@:native ("flash.events.IOErrorEvent")
extern class IOErrorEvent extends ErrorEvent {
	function new(type : String, bubbles : Bool = false, cancelable : Bool = false, ?text : String, id : Int = 0) : Void;
	static var DISK_ERROR : String;
	static var IO_ERROR : String;
	static var NETWORK_ERROR : String;
	static var VERIFY_ERROR : String;
}



#else


package nme.events;

import nme.display.InteractiveObject;

class IOErrorEvent extends ErrorEvent
{
   static public var IO_ERROR = "ioError";

   public function new(inType:String, bubbles:Bool = true, cancelable:Bool = false,
         text:String = "", id:Int= 0)
   {
      super(inType,bubbles,cancelable,text,id);
   }
}


#end