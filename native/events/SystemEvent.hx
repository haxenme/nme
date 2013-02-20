package native.events;
#if (cpp || neko)

class SystemEvent extends Event 
{
   public static var SYSTEM:String = "system";

   public var data(default, null):Int;

   public function new(type:String, bubbles:Bool = false, cancelable:Bool = false, data:Int = 0) 
   {
      super(type, bubbles, cancelable);
      this.data = data;
   }

   public override function clone():Event 
   {
      return new ErrorEvent(type, bubbles, cancelable, data);
   }

   public override function toString():String 
   {
      return "[SystemEvent type=" + type + " bubbles=" + bubbles + " cancelable=" + cancelable + " data=" + data + "]";
   }
}

#end