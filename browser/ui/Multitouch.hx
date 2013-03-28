package browser.ui;
#if js


import browser.ui.MultitouchInputMode;
import browser.Lib;
import js.Browser;


class Multitouch {
	
	
	public static var inputMode(get_inputMode, set_inputMode):MultitouchInputMode;
	public static var maxTouchPoints(default, null):Int;
	public static var supportedGestures(default, null):Array<String>;
	public static var supportsGestureEvents(default, null):Bool;
	public static var supportsTouchEvents(get_supportsTouchEvents, null):Bool;
	
	
	public static function __init__() {
		
		maxTouchPoints = 2;
		supportedGestures = [];
		supportsGestureEvents = false;
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private static function get_inputMode():MultitouchInputMode {
		
		return MultitouchInputMode.TOUCH_POINT;
		
	}
	
	
	private static function set_inputMode(inMode:MultitouchInputMode):MultitouchInputMode {
		
		if (inMode == MultitouchInputMode.GESTURE) {
			
			return inputMode;
			
		}
		
		// @todo set input mode
		return inMode;
		
	}
	
	
	private static function get_supportsTouchEvents():Bool {
		
		// just one of many possible tests from http://modernizr.github.com/Modernizr/touch.html
		var supported = Reflect.hasField(Browser.window, "ontouchstart");
		return supported;
		
	}
	
	
}


#end