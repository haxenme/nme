package nme.ui;
#if (!flash)

import nme.ui.MultitouchInputMode;
import nme.Lib;
import nme.PrimeLoader;

@:nativeProperty
class Multitouch 
{
   public static var inputMode(get, set):MultitouchInputMode;
   public static var maxTouchPoints(default, null):Int;
   public static var supportedGestures(default, null):Array<String>;
   public static var supportsGestureEvents(default, null):Bool;
   public static var supportsTouchEvents(get, null):Bool;

   public static function __init__() 
   {
      maxTouchPoints = 2;
      supportedGestures = [];
      supportsGestureEvents = false;
   }

   // Getters & Setters
   private static function get_inputMode():MultitouchInputMode 
   {
      // No gestures at the moment...
      if (nme_stage_get_multitouch_active(Lib.current.stage.nmeHandle))
         return MultitouchInputMode.TOUCH_POINT;
      else
         return MultitouchInputMode.NONE;
   }

   private static function set_inputMode(inMode:MultitouchInputMode):MultitouchInputMode 
   {
      if (inMode == MultitouchInputMode.GESTURE)
         return inputMode;

      // No gestures at the moment...
      nme_stage_set_multitouch_active(Lib.current.stage.nmeHandle, inMode == MultitouchInputMode.TOUCH_POINT);
      return inMode;
   }

   private static function get_supportsTouchEvents():Bool { return nme_stage_get_multitouch_supported(Lib.current.stage.nmeHandle); }

   // Native Methods
   private static var nme_stage_get_multitouch_supported = PrimeLoader.load("nme_stage_get_multitouch_supported", "ob");
   private static var nme_stage_get_multitouch_active = PrimeLoader.load("nme_stage_get_multitouch_active", "ob");
   private static var nme_stage_set_multitouch_active = PrimeLoader.load("nme_stage_set_multitouch_active", "obv");
}

#else
typedef Multitouch = flash.ui.Multitouch;
#end
