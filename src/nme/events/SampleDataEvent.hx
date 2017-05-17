package nme.events;
#if (!flash)

import nme.utils.ByteArray;

@:nativeProperty
class SampleDataEvent extends Event 
{
   public static inline var SAMPLE_DATA:String = "sampleData";

   public var data:ByteArray;
   public var position:Float;

   public function new(type:String, bubbles:Bool = false, cancelable:Bool = false) 
   {
      super(type, bubbles, cancelable);

      data = new ByteArray();
      data.bigEndian = false;
      position = 0.0;
   }

   public override function clone():Event 
   {
      return new SampleDataEvent(type, bubbles, cancelable);
   }

   public override function toString():String 
   {
      return "[SampleDataEvent type=" + type + " bubbles=" + bubbles + " cancelable=" + cancelable + "]";
   }
}

#else
typedef SampleDataEvent = flash.events.SampleDataEvent;
#end
