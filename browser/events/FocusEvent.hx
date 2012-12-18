package browser.events;


import browser.display.InteractiveObject;


class FocusEvent extends Event {
	
	
	public static var FOCUS_IN = "focusIn";
	public static var FOCUS_OUT = "focusOut";
	public static var KEY_FOCUS_CHANGE = "keyFocusChange";
	public static var MOUSE_FOCUS_CHANGE = "mouseFocusChange";
	
	public var keyCode:Int;
	public var relatedObject:InteractiveObject;
	public var shiftKey:Bool;
	
	
	public function new (type:String, bubbles:Bool = false, cancelable:Bool = false, inObject:InteractiveObject = null, inShiftKey:Bool = false, inKeyCode:Int = 0) {
		
		super (type, bubbles, cancelable);
		
		keyCode = inKeyCode;
		shiftKey = (inShiftKey == null ? false : inShiftKey);
		target = inObject;
		
	}
	
	
}