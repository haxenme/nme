package nme.events;


import nme.ui.GameInputDevice;


class GameInputEvent extends Event
{
   public static inline var DEVICE_ADDED = "deviceAdded";
   public static inline var DEVICE_REMOVED = "deviceRemoved";
   public static inline var DEVICE_UNUSABLE = "deviceUnusable";

   public var device(default, null):GameInputDevice;


   public function new(type:String, bubbles:Bool = true, cancelable:Bool = false, inDevice:GameInputDevice = null)
   {
      super(type, bubbles, cancelable);
      device = inDevice;
   }

   public override function clone():Event
   {
      var event = new GameInputEvent(type, bubbles, cancelable, device);
      event.target = target;
      event.currentTarget = currentTarget;
      return event;
   }
}

