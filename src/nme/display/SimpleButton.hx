package nme.display;
#if (!flash)

import nme.PrimeLoader;

@:nativeProperty
class SimpleButton extends InteractiveObject 
{
   public var downState(default, set):DisplayObject;
   public var enabled(get, set):Bool;
   public var hitTestState(default, set):DisplayObject;
   public var overState(default, set):DisplayObject;
   //public var soundTransform:SoundTransform;
   //public var trackAsMenu:Bool;
   public var upState(default, set):DisplayObject;
   public var useHandCursor(get, set):Bool;

   public function new(?upState:DisplayObject, ?overState:DisplayObject, ?downState:DisplayObject, ?hitTestState:DisplayObject) 
   {
      super(nme_simple_button_create(), "SimpleButton");

      this.upState = upState;
      this.overState = overState;
      this.downState = downState;
      this.hitTestState = hitTestState;
   }

   // Getters & Setters
   private function set_downState(inState:DisplayObject) 
   {
      downState = inState;
      nme_simple_button_set_state(nmeHandle, 1, inState == null ? null : inState.nmeHandle);
      return inState;
   }

   private function get_enabled():Bool { return nme_simple_button_get_enabled(nmeHandle); }
   private function set_enabled(inVal):Bool 
   {
      nme_simple_button_set_enabled(nmeHandle, inVal);
      return inVal;
   }

   private function get_useHandCursor():Bool { return nme_simple_button_get_hand_cursor(nmeHandle); }
   private function set_useHandCursor(inVal):Bool 
   {
      nme_simple_button_set_hand_cursor(nmeHandle, inVal);
      return inVal;
   }

   private function set_hitTestState(inState:DisplayObject) 
   {
      hitTestState = inState;
      nme_simple_button_set_state(nmeHandle, 3, inState == null ? null : inState.nmeHandle);
      return inState;
   }

   public function set_overState(inState:DisplayObject) 
   {
      overState = inState;
      nme_simple_button_set_state(nmeHandle, 2, inState == null ? null : inState.nmeHandle);
      return inState;
   }

   public function set_upState(inState:DisplayObject) 
   {
      upState = inState;
      nme_simple_button_set_state(nmeHandle, 0, inState == null ? null : inState.nmeHandle);
      return inState;
   }

   // Native Methods
   private static var nme_simple_button_set_state = PrimeLoader.load("nme_simple_button_set_state", "oiov");
   private static var nme_simple_button_get_enabled = PrimeLoader.load("nme_simple_button_get_enabled", "ob");
   private static var nme_simple_button_set_enabled = PrimeLoader.load("nme_simple_button_set_enabled", "obv");
   private static var nme_simple_button_get_hand_cursor = PrimeLoader.load("nme_simple_button_get_hand_cursor", "ob");
   private static var nme_simple_button_set_hand_cursor = PrimeLoader.load("nme_simple_button_set_hand_cursor", "obv");
   private static var nme_simple_button_create = PrimeLoader.load("nme_simple_button_create", "o");
}

#else
typedef SimpleButton = flash.display.SimpleButton;
#end
