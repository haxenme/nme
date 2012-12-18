package browser.events;

class KeyboardEvent extends Event {
	
	
	public static var KEY_DOWN = "keyDown";
	public static var KEY_UP = "keyUp";
	
	public var altKey:Bool;
	public var keyCode:Int;
	public var charCode:Int;
	public var ctrlKey:Bool;
	public var shiftKey:Bool;
	public var keyLocation:Int;
	
	
	public function new (type:String, bubbles:Bool = false, cancelable:Bool = false, inCharCode:Int = 0, inKeyCode:Int = 0, inKeyLocation:Int = 0, inCtrlKey:Bool = false, inAltKey:Bool = false, inShiftKey:Bool = false) {
		
		super (type, bubbles, cancelable);
		
		keyCode = inKeyCode;
		keyLocation = (inKeyLocation == null ? 0 : inKeyLocation);
		charCode = (inCharCode == null ? 0 : inCharCode);
		shiftKey = (inShiftKey == null ? false : inShiftKey);
		altKey = (inAltKey == null ? false : inAltKey);
		ctrlKey = (inCtrlKey == null ? false : inCtrlKey);
		
	}
	
	
}