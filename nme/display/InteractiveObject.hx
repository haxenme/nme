package nme.display;
#if (cpp || neko)


import nme.Loader;


class InteractiveObject extends DisplayObject {
	
	
	public var doubleClickEnabled:Bool;
	public var mouseEnabled (nmeGetMouseEnabled, nmeSetMouseEnabled):Bool;
	public var moveForSoftKeyboard (nmeGetMoveForSoftKeyboard, nmeSetMoveForSoftKeyboard):Bool;
	public var needsSoftKeyboard (nmeGetNeedsSoftKeyboard, nmeSetNeedsSoftKeyboard):Bool;
	
	private var nmeMouseEnabled:Bool;
	
	
	public function new (inHandle:Dynamic, inType:String) {
		
		doubleClickEnabled = false;
		nmeMouseEnabled = true;
		
		super (inHandle, inType);
		
	}
	
	
	override private function nmeAsInteractiveObject ():InteractiveObject {
		
		return this;
		
	}
	
	
	public function requestSoftKeyboard ():Bool {
		
		return nme_display_object_request_soft_keyboard (nmeHandle);
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function nmeGetMouseEnabled ():Bool { return nmeMouseEnabled; }
	private function nmeSetMouseEnabled (inVal:Bool):Bool {
		
		nmeMouseEnabled = inVal;
		nme_display_object_set_mouse_enabled (nmeHandle, inVal);
		return nmeMouseEnabled;
		
	}
	
	
	private function nmeSetMoveForSoftKeyboard (inVal:Bool):Bool {
		
		nme_display_object_set_moves_for_soft_keyboard (nmeHandle, inVal);
		return inVal;
		
	}
	
	
	private function nmeGetMoveForSoftKeyboard ():Bool {
		
		return nme_display_object_get_moves_for_soft_keyboard (nmeHandle);
		
	}
	
	
	private function nmeSetNeedsSoftKeyboard (inVal):Bool {
		
		nme_display_object_set_needs_soft_keyboard (nmeHandle, inVal);
		return inVal;
		
	}
	
	
	private function nmeGetNeedsSoftKeyboard ():Bool {
		
		return nme_display_object_get_needs_soft_keyboard (nmeHandle);
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	private static var nme_display_object_set_mouse_enabled = Loader.load ("nme_display_object_set_mouse_enabled", 2);
	private static var nme_display_object_set_needs_soft_keyboard = Loader.load ("nme_display_object_set_needs_soft_keyboard", 2);
	private static var nme_display_object_get_needs_soft_keyboard = Loader.load ("nme_display_object_get_needs_soft_keyboard", 1);
	private static var nme_display_object_set_moves_for_soft_keyboard = Loader.load ("nme_display_object_set_moves_for_soft_keyboard", 2);
	private static var nme_display_object_get_moves_for_soft_keyboard = Loader.load ("nme_display_object_get_moves_for_soft_keyboard", 1);
	private static var nme_display_object_request_soft_keyboard = Loader.load ("nme_display_object_request_soft_keyboard", 1);
	
	
}


#else
typedef InteractiveObject = flash.display.InteractiveObject;
#end