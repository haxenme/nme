package nme.events;

import nme.display.InteractiveObject;

class IOErrorEvent extends nme.events.Event
{
   static public var IO_ERROR = "ioError";
	var nmeString : String;

   public function new(inType:String, bubbles:Bool = true, cancelable:Bool = false,
         text:String = "", id:Int= 0)
   {
      super(inType,bubbles,cancelable);
		nmeString = text;
   }

	public override function toString() { return nmeString; }
}
