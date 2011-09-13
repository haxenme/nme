package nme.events;
#if cpp || neko


class ErrorEvent extends TextEvent
{
   public var errorID(default,null):Int;


   public function new(type:String, bubbles:Bool = false, cancelable:Bool = false, text:String = "", inID:Int)
   {
      super(type,bubbles,cancelable,text);
      errorID = inID;
   }

	public override function toString() { return text; }
}


#else
typedef ErrorEvent = flash.events.ErrorEvent;
#end