package native.sensors;
#if (cpp || neko)

import native.errors.ArgumentError;
import native.events.AccelerometerEvent;
import native.events.EventDispatcher;
import native.Loader;
import haxe.Timer;

class Accelerometer extends EventDispatcher 
{
   public static var isSupported(get_isSupported, null):Bool;

   public var muted(default, null):Bool;

   private static var defaultInterval:Int = 34;

   /** @private */ private var timer:Timer;
   public function new() 
   {
      super();

      setRequestedUpdateInterval(defaultInterval);
   }

   override public function addEventListener(type:String, listener:Function, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void 
   {
      super.addEventListener(type, listener, useCapture, priority, useWeakReference);
      update();
   }

   public function setRequestedUpdateInterval(interval:Float):Void 
   {
      if (interval < 0) 
      {
         throw new ArgumentError();

      } else if (interval == 0) 
      {
         interval = defaultInterval;
      }

      if (timer != null) 
      {
         timer.stop();
      }

      if (isSupported) 
      {
         timer = new Timer(interval);
         timer.run = update;
      }
   }

   /** @private */ private function update():Void {
      var event = new AccelerometerEvent(AccelerometerEvent.UPDATE);

      var data = nme_input_get_acceleration();

      event.timestamp = Timer.stamp();
      event.accelerationX = data.x;
      event.accelerationY = data.y;
      event.accelerationZ = data.z;

      dispatchEvent(event);
   }

   // Getters & Setters
   /** @private */ private static function get_isSupported():Bool { return nme_input_get_acceleration() != null; }
   // Native Methods
   private static var nme_input_get_acceleration = Loader.load("nme_input_get_acceleration", 0);
}

typedef Function = Dynamic -> Void;

#end