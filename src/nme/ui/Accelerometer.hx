package nme.ui;
#if (!flash)

import nme.PrimeLoader;

@:nativeProperty
class Accelerometer 
{
   public static function get(inAcceleration:Acceleration=null):Acceleration 
   {
      var bIsSupported:Bool = nme_input_get_acceleration_support();
      if(bIsSupported)
      {
        var x:Float = nme_input_get_acceleration_x();
        var y:Float = nme_input_get_acceleration_y();
        var z:Float = nme_input_get_acceleration_z();
        if(inAcceleration==null)
        {
            return new Acceleration(x,y,z);
        }
        else
        {
            inAcceleration.x = x;
            inAcceleration.x = y;
            inAcceleration.x = z;
            return inAcceleration;
        }
      }
      // returns null if device not supported
      return null;
   }
   private static var nme_input_get_acceleration_support = PrimeLoader.load("nme_input_get_acceleration_support", "b");
   private static var nme_input_get_acceleration_x = PrimeLoader.load("nme_input_get_acceleration_x", "d");
   private static var nme_input_get_acceleration_y = PrimeLoader.load("nme_input_get_acceleration_y", "d");
   private static var nme_input_get_acceleration_z = PrimeLoader.load("nme_input_get_acceleration_z", "d");
}

#end
