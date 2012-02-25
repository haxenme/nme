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


	public function new(type:String, bubbles:Bool = false, cancelable:Bool = false, charCodeValue:Int = 0, keyCodeValue:Int = 0, keyLocationValue:Int = 0, ctrlKeyValue:Bool = false, altKeyValue:Bool = false, shiftKeyValue:Bool = false, controlKeyValue:Bool = false, commandKeyValue:Bool = false)
	{
		super(type, bubbles, cancelable);
		
		keyCode = keyCodeValue;
		keyLocation = keyLocationValue == null ? 0 : keyLocationValue;
		charCode = charCodeValue == null ? 0 : charCodeValue;
		
		shiftKey = shiftKeyValue == null ? false : shiftKeyValue;
		altKey = altKeyValue == null ? false : altKeyValue;
		ctrlKey = ctrlKeyValue == null ? false : ctrlKeyValue;
	}
	
	
	public override function clone ():Event
	{
		return new KeyboardEvent (type, bubbles, cancelable, charCode, keyCode, keyLocation, ctrlKey, altKey, shiftKey);
	}
	
	
	public override function toString ():String
	{
		return "[KeyboardEvent type=" + type + " bubbles=" + bubbles + " cancelable=" + cancelable + " charCode=" + charCode + " keyCode=" + keyCode + " keyLocation=" + keyLocation + " ctrlKey=" + ctrlKey + " altKey=" + altKey + " shiftKey=" + shiftKey + "]";
	}
	
}


#elseif js

class KeyboardEvent extends flash.events.Event
{
   public var keyCode : Int;
   public var charCode : Int;
   public var keyLocation : Int;

   public var ctrlKey : Bool;
   public var altKey : Bool;
   public var shiftKey : Bool;


   public function new(type : String, ?bubbles : Bool, ?cancelable : Bool,
         ?inCharCode : Int, ?inKeyCode : Int, ?inKeyLocation : Int,
         ?inCtrlKey : Bool, ?inAltKey : Bool, ?inShiftKey : Bool)
   {
      super(type,bubbles,cancelable);

      keyCode = inKeyCode;
      keyLocation = inKeyLocation==null ? 0 : inKeyLocation;
      charCode = inCharCode==null ? 0 : inCharCode;

      shiftKey = inShiftKey==null ? false : inShiftKey;
      altKey = inAltKey==null ? false : inAltKey;
      ctrlKey = inCtrlKey==null ? false : inCtrlKey;
   }


   public static var KEY_DOWN = "KEY_DOWN";
   public static var KEY_UP = "KEY_UP";

}

#else
typedef KeyboardEvent = flash.events.KeyboardEvent;
#end