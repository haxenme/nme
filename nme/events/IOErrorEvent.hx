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
