package nme.feedback;
#if (!flash)

import nme.PrimeLoader;

@:nativeProperty
class Haptic 
{
   public static function vibrate(period:Int = 0, duration:Int = 1000):Void 
   {
      #if cpp
      nme_haptic_vibrate(period, duration);
      #end
   }

   // Native Methods
   #if cpp
   static var nme_haptic_vibrate = PrimeLoader.load("nme_haptic_vibrate", "iiv");
   #end
}

#end
