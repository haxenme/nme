package nme.events;
#if (cpp || neko)


import nme.display.InteractiveObject;


class FocusEvent extends Event
{

	static public var FOCUS_IN = "focusIn";
	static public var FOCUS_OUT = "focusOut";
	static public var KEY_FOCUS_CHANGE = "keyFocusChange";
	static public var MOUSE_FOCUS_CHANGE = "mouseFocusChange";
	
	public var keyCode(default, null):Int;
	public var relatedObject(default, null):InteractiveObject;
	public var shiftKey(default, null):Bool;
	
	
	public function new(inType:String, bubbles:Bool = true, cancelable:Bool = false, relatedObject:InteractiveObject = null, shiftKey:Bool = false, keyCode:Int = 0, direction:String = "none")
	{
		super(inType, bubbles, cancelable);
		this.relatedObject = relatedObject;
		this.keyCode = keyCode;
		this.shiftKey = shiftKey;
	}
	
	
	public override function clone ():Event
	{
		return new FocusEvent (type, bubbles, cancelable, relatedObject, shiftKey, keyCode);
	}
	
	
	public override function toString ():String
	{
		return "[FocusEvent type=" + type + " bubbles=" + bubbles + " cancelable=" + cancelable + " relatedObject=" + relatedObject + " shiftKey=" + shiftKey + " keyCode=" + keyCode + "]";
	}
	
}


#elseif js

class FocusEvent extends flash.events.Event
{
   public var keyCode : Int;
   public var shiftKey : Bool;
   public var relatedObject : flash.display.InteractiveObject;

   public function new(type : String, ?bubbles : Bool, ?cancelable : Bool,
         ?inObject : flash.display.InteractiveObject,
         ?inShiftKey : Bool,
         ?inKeyCode : Int)
   {
      super(type,bubbles,cancelable);

      keyCode = inKeyCode;
      shiftKey = inShiftKey==null ? false : inShiftKey;
      target = inObject;
   }

   public static var FOCUS_IN = "FOCUS_IN";
   public static var FOCUS_OUT = "FOCUS_OUT";
   public static var KEY_FOCUS_CHANGE = "KEY_FOCUS_CHANGE";
   public static var MOUSE_FOCUS_CHANGE = "MOUSE_FOCUS_CHANGE";

}

#else
typedef FocusEvent = flash.events.FocusEvent;
#end