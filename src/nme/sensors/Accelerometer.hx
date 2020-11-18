package nme.sensors;
#if (!flash)

import haxe.ds.Option;
import nme.errors.ArgumentError;
import nme.events.AccelerometerEvent;
import nme.events.EventDispatcher;
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

   /** @private */ private var timer:Option<Timer> = None;
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

      switch (timer) {
         case None:
         case Some(t):
            t.stop();
      }

      if (isSupported) 
      {
         var t:Timer = new Timer(interval);
         t.run = update;
         timer = Some(t);
      }
   }

    public function removeInterval():Void {
       switch (timer) {
          case None:
          case Some(t):
             t.stop();
       }
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
