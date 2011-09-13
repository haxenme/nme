package nme.display;
#if cpp || neko


class SimpleButton extends InteractiveObject
{
   public var downState(default,nmeSetDownState) : DisplayObject;
   public var overState(default,nmeSetOverState) : DisplayObject;
   public var upState(default,nmeSetUpState) : DisplayObject;
   public var hitTestState(default,nmeSetHitTestState) : DisplayObject;
 	public var useHandCursor(nmeGetHandCursor,nmeSetHandCursor) : Bool;
   public var enabled(nmeGetEnabled, nmeSetEnabled) : Bool;
 	// var soundTransform : SoundTransform;
   // var trackAsMenu : Bool;

   public function new(?upState:DisplayObject, ?overState:DisplayObject, ?downState:DisplayObject, ?hitTestState:DisplayObject)
   {
      super(nme_simple_button_create(), "SimpleButton");
      nmeSetUpState(upState);
      nmeSetOverState(overState);
      nmeSetDownState(downState);
      nmeSetHitTestState(hitTestState);
   }

   public function nmeSetUpState(inState:DisplayObject)
   {
       upState = inState;
       nme_simple_button_set_state(nmeHandle,0,inState==null ? null : inState.nmeHandle);
       return inState;
   }
   public function nmeSetDownState(inState:DisplayObject)
   {
       downState = inState;
       nme_simple_button_set_state(nmeHandle,1,inState==null ? null : inState.nmeHandle);
       return inState;
   }
   public function nmeSetOverState(inState:DisplayObject)
   {
       overState = inState;
       nme_simple_button_set_state(nmeHandle,2,inState==null ? null : inState.nmeHandle);
       return inState;
   }
   public function nmeSetHitTestState(inState:DisplayObject)
   {
       hitTestState = inState;
       nme_simple_button_set_state(nmeHandle,3,inState==null ? null : inState.nmeHandle);
       return inState;
   }

   public function nmeGetEnabled():Bool { return nme_simple_button_get_enabled(nmeHandle); }
   public function nmeSetEnabled(inVal):Bool
   {
      nme_simple_button_set_enabled(nmeHandle,inVal);
      return inVal;
   }
   public function nmeGetHandCursor():Bool { return nme_simple_button_get_hand_cursor(nmeHandle); }
   public function nmeSetHandCursor(inVal):Bool
   {
      nme_simple_button_set_hand_cursor(nmeHandle,inVal);
      return inVal;
   }




   static var nme_simple_button_set_state = nme.Loader.load("nme_simple_button_set_state",3);

   static var nme_simple_button_get_enabled = nme.Loader.load("nme_simple_button_get_enabled",1);
   static var nme_simple_button_set_enabled = nme.Loader.load("nme_simple_button_set_enabled",2);
   static var nme_simple_button_get_hand_cursor = nme.Loader.load("nme_simple_button_get_hand_cursor",1);
   static var nme_simple_button_set_hand_cursor = nme.Loader.load("nme_simple_button_set_hand_cursor",2);
   static var nme_simple_button_create = nme.Loader.load("nme_simple_button_create",0);

}


#else
typedef SimpleButton = flash.display.SimpleButton;
#end