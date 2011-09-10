package nme.display;


#if flash
@:native ("flash.display.InteractiveObject")
extern class InteractiveObject extends DisplayObject {
	var accessibilityImplementation : nme.accessibility.AccessibilityImplementation;
	var contextMenu : nme.ui.ContextMenu;
	var doubleClickEnabled : Bool;
	var focusRect : Dynamic;
	var mouseEnabled : Bool;
	var tabEnabled : Bool;
	var tabIndex : Int;
	function new() : Void;
}
#else



class InteractiveObject extends DisplayObject
{
   public var mouseEnabled(nmeGetMouseEnabled,nmeSetMouseEnabled):Bool;
   public var needsSoftKeyboard(nmeGetNeedsSoftKeyboard,nmeSetNeedsSoftKeyboard):Bool;
   public var moveForSoftKeyboard(nmeGetMoveForSoftKeyboard,nmeSetMoveForSoftKeyboard):Bool;

	var nmeMouseEnabled:Bool;
   public var doubleClickEnabled:Bool;

   function new(inHandle:Dynamic,inType:String)
   {
      doubleClickEnabled = false;
	   nmeMouseEnabled = true;
      super(inHandle,inType);
   }

	function nmeGetMouseEnabled() : Bool { return nmeMouseEnabled; }
	function nmeSetMouseEnabled(inVal:Bool) : Bool
	{
	   nmeMouseEnabled = inVal;
		nme_display_object_set_mouse_enabled(nmeHandle, inVal);
	   return nmeMouseEnabled;
	}

  	function nmeSetNeedsSoftKeyboard(inVal) : Bool
   {
      nme_display_object_set_needs_soft_keyboard(nmeHandle,inVal);
      return inVal;
   }
   function nmeGetNeedsSoftKeyboard() : Bool
   {
      return nme_display_object_get_needs_soft_keyboard(nmeHandle);
   }

   function nmeSetMoveForSoftKeyboard(inVal:Bool) : Bool
   {
      nme_display_object_set_moves_for_soft_keyboard(nmeHandle,inVal);
      return inVal;
   }
   function nmeGetMoveForSoftKeyboard() : Bool
   {
      return nme_display_object_get_moves_for_soft_keyboard(nmeHandle);
   }



   public function requestSoftKeyboard() : Bool
   {
      return nme_display_object_request_soft_keyboard(nmeHandle);
   }

	override function nmeAsInteractiveObject() : InteractiveObject { return this; }


   static var nme_display_object_set_mouse_enabled = nme.Loader.load("nme_display_object_set_mouse_enabled",2);
   static var nme_display_object_set_needs_soft_keyboard =
      nme.Loader.load("nme_display_object_set_needs_soft_keyboard",2);
   static var nme_display_object_get_needs_soft_keyboard =
      nme.Loader.load("nme_display_object_get_needs_soft_keyboard",1);
   static var nme_display_object_set_moves_for_soft_keyboard =
      nme.Loader.load("nme_display_object_set_moves_for_soft_keyboard",2);
   static var nme_display_object_get_moves_for_soft_keyboard =
      nme.Loader.load("nme_display_object_get_moves_for_soft_keyboard",1);
   static var nme_display_object_request_soft_keyboard =
      nme.Loader.load("nme_display_object_request_soft_keyboard",1);
}
#end