package native.display;


import native.Loader;


class InteractiveObject extends DisplayObject {
	
	
	public var doubleClickEnabled:Bool;
	public var mouseEnabled (get_mouseEnabled, set_mouseEnabled):Bool;
	public var moveForSoftKeyboard (get_moveForSoftKeyboard, set_moveForSoftKeyboard):Bool;
	public var needsSoftKeyboard (get_needsSoftKeyboard, set_needsSoftKeyboard):Bool;
	
	/** @private */ private var nmeMouseEnabled:Bool;
	
	
	public function new (inHandle:Dynamic, inType:String) {
		
		doubleClickEnabled = false;
		nmeMouseEnabled = true;
		
		super (inHandle, inType);
		
	}
	
	
	/** @private */ override private function nmeAsInteractiveObject ():InteractiveObject {
		
		return this;
		
	}
	
	
	public function requestSoftKeyboard ():Bool {
		
		return nme_display_object_request_soft_keyboard (nmeHandle);
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function get_mouseEnabled ():Bool { return nmeMouseEnabled; }
	private function set_mouseEnabled (inVal:Bool):Bool {
		
		nmeMouseEnabled = inVal;
		nme_display_object_set_mouse_enabled (nmeHandle, inVal);
		return nmeMouseEnabled;
		
	}
	
	
	private function set_moveForSoftKeyboard (inVal:Bool):Bool {
		
		nme_display_object_set_moves_for_soft_keyboard (nmeHandle, inVal);
		return inVal;
		
	}
	
	
	private function get_moveForSoftKeyboard ():Bool {
		
		return nme_display_object_get_moves_for_soft_keyboard (nmeHandle);
		
	}
	
	
	private function set_needsSoftKeyboard (inVal):Bool {
		
		nme_display_object_set_needs_soft_keyboard (nmeHandle, inVal);
		return inVal;
		
	}
	
	
	private function get_needsSoftKeyboard ():Bool {
		
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