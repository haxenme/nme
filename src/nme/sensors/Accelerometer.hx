package nme.sensors;
#if (!flash)

import nme.errors.ArgumentError;
import nme.events.AccelerometerEvent;
import nme.events.EventDispatcher;
import nme.Loader;
import haxe.Timer;

private class Data
{
   public var x:Float;
   public var y:Float;
   public var z:Float;

   public function new()
   {
      x = y = z = 0.0;
   }
}

@:nativeProperty
class Accelerometer extends EventDispatcher 
{
   public static var isSupported(get, null):Bool;

   public var muted(default, null):Bool;

   private static var defaultInterval:Int = 34;

   var data:Data;

   /** @private */ private var timer:Timer;
   public function new() 
   {
      super();

      data = new Data();

      setRequestedUpdateInterval(defaultInterval);
   }

   override public function addEventListener(type:String, listener:Function, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void 
   {
      super.addEventListener(type, listener, useCapture, priority, useWeakReference);
      update();
   }

   public static function get_isSupported() return nme.ui.Accelerometer.isSupported();

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

    public function removeInterval():Void {
        timer.stop();
    }

   /** @private */ private function update():Void {
      var event = new AccelerometerEvent(AccelerometerEvent.UPDATE);

      nme.ui.Accelerometer.get(data);

      event.timestamp = Timer.stamp();
      event.accelerationX = data.x;
      event.accelerationY = data.y;
      event.accelerationZ = data.z;

      dispatchEvent(event);
   }

}

typedef Function = Dynamic -> Void;

#else
typedef Accelerometer = flash.sensors.Accelerometer;
#end
