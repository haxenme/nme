package nme.events;
#if (!flash)

@:nativeProperty
class IOErrorEvent extends ErrorEvent 
{
   public static inline var IO_ERROR = "ioError";

   public function new(inType:String, bubbles:Bool = true, cancelable:Bool = false, text:String = "", id:Int = 0) 
   {
      super(inType, bubbles, cancelable, text, id);
   }

   public override function clone():Event 
   {
      return new IOErrorEvent(type, bubbles, cancelable, text, errorID);
   }

   public override function toString():String 
   {
      return "[IOErrorEvent type=" + type + " bubbles=" + bubbles + " cancelable=" + cancelable + " text=" + text + " errorID=" + errorID + "]";
   }
}

#else
typedef IOErrorEvent = flash.events.IOErrorEvent;
#end
