package neash.display;


import neash.Loader;


class InteractiveObject extends DisplayObject
{	
	
	public var doubleClickEnabled:Bool;
	public var mouseEnabled(nmeGetMouseEnabled, nmeSetMouseEnabled):Bool;
	public var moveForSoftKeyboard(nmeGetMoveForSoftKeyboard, nmeSetMoveForSoftKeyboard):Bool;
	public var needsSoftKeyboard(nmeGetNeedsSoftKeyboard, nmeSetNeedsSoftKeyboard):Bool;
	
	/** @private */ private var nmeMouseEnabled:Bool;
	
	
	public function new(inHandle:Dynamic, inType:String)
	{	
		doubleClickEnabled = false;
		nmeMouseEnabled = true;
		
		super(inHandle, inType);
	}
	
	
	/** @private */ override private function nmeAsInteractiveObject():InteractiveObject
	{	
		return this;	
	}
	
	
	public function requestSoftKeyboard():Bool
	{
		return nme_display_object_request_soft_keyboard(nmeHandle);	
	}
	
	
	
	// Getters & Setters
	
	
	
	/** @private */ private function nmeGetMouseEnabled():Bool { return nmeMouseEnabled; }
	/** @private */ private function nmeSetMouseEnabled(inVal:Bool):Bool
	{	
		nmeMouseEnabled = inVal;
		nme_display_object_set_mouse_enabled(nmeHandle, inVal);
		return nmeMouseEnabled;	
	}
	
	
	/** @private */ private function nmeSetMoveForSoftKeyboard(inVal:Bool):Bool
	{	
		nme_display_object_set_moves_for_soft_keyboard(nmeHandle, inVal);
		return inVal;
	}
	
	
	/** @private */ private function nmeGetMoveForSoftKeyboard():Bool
	{	
		return nme_display_object_get_moves_for_soft_keyboard(nmeHandle);
	}
	
	
	/** @private */ private function nmeSetNeedsSoftKeyboard(inVal):Bool
	{	
		nme_display_object_set_needs_soft_keyboard(nmeHandle, inVal);
		return inVal;
	}
	
	
	/** @private */ private function nmeGetNeedsSoftKeyboard():Bool
	{	
		return nme_display_object_get_needs_soft_keyboard(nmeHandle);	
	}
	
	
	
	// Native Methods
	
	
	
	private static var nme_display_object_set_mouse_enabled = Loader.load("nme_display_object_set_mouse_enabled", 2);
	private static var nme_display_object_set_needs_soft_keyboard = Loader.load("nme_display_object_set_needs_soft_keyboard", 2);
	private static var nme_display_object_get_needs_soft_keyboard = Loader.load("nme_display_object_get_needs_soft_keyboard", 1);
	private static var nme_display_object_set_moves_for_soft_keyboard = Loader.load("nme_display_object_set_moves_for_soft_keyboard", 2);
	private static var nme_display_object_get_moves_for_soft_keyboard = Loader.load("nme_display_object_get_moves_for_soft_keyboard", 1);
	private static var nme_display_object_request_soft_keyboard = Loader.load("nme_display_object_request_soft_keyboard", 1);
	
}