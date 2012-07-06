package jeash.ui;

import jeash.ui.MultitouchInputMode;

class Multitouch
{
	
	public static var inputMode(nmeGetInputMode, nmeSetInputMode):MultitouchInputMode;
	public static var maxTouchPoints(default, null):Int;
	public static var supportedGestures(default, null):Array<String>;
	public static var supportsGestureEvents(default, null):Bool;
	public static var supportsTouchEvents(nmeGetSupportsTouchEvents, null):Bool;
	
	public static function __init__() {
		maxTouchPoints = 2;
		supportedGestures = [];
		supportsGestureEvents = false;
	}
	
	/** @private */ private static function nmeGetInputMode():MultitouchInputMode {
		return MultitouchInputMode.TOUCH_POINT;
	}

	/** @private */ private static function nmeSetInputMode(inMode:MultitouchInputMode):MultitouchInputMode {
		if (inMode == MultitouchInputMode.GESTURE)
			return nmeGetInputMode();
		
		// @todo set input mode
		return inMode;
	}

	/** @private */ private static function nmeGetSupportsTouchEvents():Bool {
		// just one of many possible tests from http://modernizr.github.com/Modernizr/touch.html
		var supported = Reflect.hasField(js.Lib.window, "ontouchstart");
		return supported;
	}
}