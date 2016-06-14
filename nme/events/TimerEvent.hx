package nme.events;
#if (!flash)

@:nativeProperty
class TimerEvent extends Event 
{
   public static inline var TIMER:String = "timer";
   public static inline var TIMER_COMPLETE:String = "timerComplete";

   public function new(type:String, bubbles:Bool = false, cancelable:Bool = false) 
   {
      super(type, bubbles, cancelable);
   }

   public override function clone():Event 
   {
      return new TimerEvent(type, bubbles, cancelable);
   }

   public override function toString():String 
   {
      return "[TimerEvent type=" + type + " bubbles=" + bubbles + " cancelable=" + cancelable + "]";
   }

   public function updateAfterEvent() 
   {
   }
}

#else
typedef TimerEvent = flash.events.TimerEvent;
#end
