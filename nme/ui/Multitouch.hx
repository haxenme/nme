#if flash


package nme.ui;


@:native ("flash.ui.Multitouch")
@:require(flash10_1) extern class Multitouch {
	static var inputMode : MultitouchInputMode;
	static var maxTouchPoints(default,null) : Int;
	static var supportedGestures(default,null) : nme.Vector<String>;
	static var supportsGestureEvents(default,null) : Bool;
	static var supportsTouchEvents(default,null) : Bool;
}



#else


package nme.ui;

import nme.ui.MultitouchInputMode;

class Multitouch
{
   public static var inputMode(nmeGetInputMode,nmeSetInputMode) : MultitouchInputMode;
   public static var maxTouchPoints(default,null) : Int;
   public static var supportedGestures(default,null) : Array<String>;
   public static var supportsGestureEvents(default,null) : Bool;
   public static var supportsTouchEvents(nmeGetSupportsTouchEvents,null) : Bool;

   public static function __init__()
   {
      maxTouchPoints = 2;
      supportedGestures = [];
      supportsGestureEvents = false;
   }

   static function nmeGetSupportsTouchEvents() : Bool
   {
      return nme_stage_get_multitouch_supported(nme.Lib.current.stage.nmeHandle);
   }

   static function nmeGetInputMode() : MultitouchInputMode
   {
      // No gestures at the moment...
      if (nme_stage_get_multitouch_active(nme.Lib.current.stage.nmeHandle))
         return MultitouchInputMode.TOUCH_POINT;
      else
         return MultitouchInputMode.NONE;
   }


   static function nmeSetInputMode(inMode:MultitouchInputMode) : MultitouchInputMode
   {
      if (inMode==MultitouchInputMode.GESTURE)
         return nmeGetInputMode();

      // No gestures at the moment...
      nme_stage_set_multitouch_active(nme.Lib.current.stage.nmeHandle, inMode == MultitouchInputMode.TOUCH_POINT );
      return inMode;
   }


   static var nme_stage_get_multitouch_supported = nme.Loader.load("nme_stage_get_multitouch_supported",1);
   static var nme_stage_get_multitouch_active = nme.Loader.load("nme_stage_get_multitouch_active",1);
   static var nme_stage_set_multitouch_active = nme.Loader.load("nme_stage_set_multitouch_active",2);
 
}

#end
