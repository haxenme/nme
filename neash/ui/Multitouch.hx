package neash.ui;


import neash.ui.MultitouchInputMode;
import neash.Loader;


class Multitouch
{
	
	public static var inputMode(nmeGetInputMode, nmeSetInputMode):MultitouchInputMode;
	public static var maxTouchPoints(default, null):Int;
	public static var supportedGestures(default, null):Array<String>;
	public static var supportsGestureEvents(default, null):Bool;
	public static var supportsTouchEvents(nmeGetSupportsTouchEvents, null):Bool;
	
	
	public static function __init__()
	{
		maxTouchPoints = 2;
		supportedGestures = [];
		supportsGestureEvents = false;
	}
	
	
	
	// Getters & Setters
	
	
	
	/** @private */ private static function nmeGetInputMode():MultitouchInputMode
	{
		// No gestures at the moment...
		if (nme_stage_get_multitouch_active(nme.Lib.current.stage.nmeHandle))
			return MultitouchInputMode.TOUCH_POINT;
		else
			return MultitouchInputMode.NONE;
	}


	/** @private */ private static function nmeSetInputMode(inMode:MultitouchInputMode):MultitouchInputMode
	{
		if (inMode == MultitouchInputMode.GESTURE)
			return nmeGetInputMode();
		
		// No gestures at the moment...
		nme_stage_set_multitouch_active(nme.Lib.current.stage.nmeHandle, inMode == MultitouchInputMode.TOUCH_POINT);
		return inMode;
	}
	
	
	/** @private */ private static function nmeGetSupportsTouchEvents():Bool { return nme_stage_get_multitouch_supported(nme.Lib.current.stage.nmeHandle); }
	
	
	
	// Native Methods
	
	
	
	private static var nme_stage_get_multitouch_supported = Loader.load("nme_stage_get_multitouch_supported", 1);
	private static var nme_stage_get_multitouch_active = Loader.load("nme_stage_get_multitouch_active", 1);
	private static var nme_stage_set_multitouch_active = Loader.load("nme_stage_set_multitouch_active", 2);
	
}