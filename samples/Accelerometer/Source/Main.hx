import nme.display.Sprite;
import nme.events.AccelerometerEvent;
import nme.sensors.Accelerometer;

class Main extends Sprite {
   
   var a:Accelerometer;

   public function new () {

      super ();
      a = new Accelerometer();
      a.addEventListener(AccelerometerEvent.UPDATE, onAccel);
      a.setRequestedUpdateInterval(30);
   }

   function onAccel(e:AccelerometerEvent):Void {
      trace('${e.accelerationX},${e.accelerationY},${e.accelerationY}');
   }
}