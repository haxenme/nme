package nme.events;
#if (cpp || neko)


class KeyboardEvent extends Event
{
	
	public static var KEY_DOWN = "keyDown";
	public static var KEY_UP = "keyUp";
	
	public var altKey:Bool;
	public var charCode:Int;
	public var ctrlKey:Bool;
	public var keyCode:Int;
	public var keyLocation:Int;
	public var shiftKey:Bool;


	public function new(type:String, ?bubbles:Bool, ?cancelable:Bool, ?inCharCode:Int, ?inKeyCode:Int, ?inKeyLocation:Int, ?inCtrlKey:Bool, ?inAltKey:Bool, ?inShiftKey:Bool)
	{
		super(type, bubbles, cancelable);
		
		keyCode = inKeyCode;
		keyLocation = inKeyLocation == null ? 0 : inKeyLocation;
		charCode = inCharCode == null ? 0 : inCharCode;
		
		shiftKey = inShiftKey == null ? false : inShiftKey;
		altKey = inAltKey == null ? false : inAltKey;
		ctrlKey = inCtrlKey == null ? false : inCtrlKey;
	}
	
}


#else
typedef KeyboardEvent = flash.events.KeyboardEvent;
#end