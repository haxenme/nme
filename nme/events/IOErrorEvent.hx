package nme.events;
#if (cpp || neko)


class IOErrorEvent extends ErrorEvent
{
	
	public static var IO_ERROR = "ioError";
	
	
	public function new(inType:String, bubbles:Bool = true, cancelable:Bool = false, text:String = "", id:Int = 0)
	{
		super(inType, bubbles, cancelable, text, id);
	}
	
	
	public override function clone ():Event
	{
		return new IOErrorEvent (type, bubbles, cancelable, text, errorID);
	}
	
	
	public override function toString ():String
	{
		return "[IOErrorEvent type=" + type + " bubbles=" + bubbles + " cancelable=" + cancelable + " text=" + text + " errorID=" + errorID + "]";
	}
	
}


#elseif js

class IOErrorEvent extends flash.events.Event
{
   public var text : String;

   public function new(type : String, ?bubbles : Bool, ?cancelable : Bool,
         ?inText : String = "")
   {
      super(type,bubbles,cancelable);

      text = inText;
   }

   public static var IO_ERROR = "IO_ERROR";

}

#else
typedef IOErrorEvent = flash.events.IOErrorEvent;
#end