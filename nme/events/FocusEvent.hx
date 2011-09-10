#if flash


package nme.events;


@:native ("flash.events.FocusEvent")
extern class FocusEvent extends Event {
	@:require(flash10) var isRelatedObjectInaccessible : Bool;
	var keyCode : UInt;
	var relatedObject : nme.display.InteractiveObject;
	var shiftKey : Bool;
	function new(type : String, bubbles : Bool = true, cancelable : Bool = false, ?relatedObject : nme.display.InteractiveObject, shiftKey : Bool = false, keyCode : UInt = 0) : Void;
	static var FOCUS_IN : String;
	static var FOCUS_OUT : String;
	static var KEY_FOCUS_CHANGE : String;
	static var MOUSE_FOCUS_CHANGE : String;
}


#else


package nme.events;

import nme.display.InteractiveObject;

class FocusEvent extends nme.events.Event
{
   static public var FOCUS_IN = "focusIn";
   static public var FOCUS_OUT = "focusOut";
   static public var KEY_FOCUS_CHANGE = "keyFocusChange";
   static public var MOUSE_FOCUS_CHANGE = "mouseFocusChange";

   public var keyCode(default,null):Int;
   public var relatedObject(default,null):InteractiveObject;
   public var shiftKey(default,null):Bool;

   public function new(inType:String, bubbles:Bool = true, cancelable:Bool = false,
         inRelatedObject:InteractiveObject = null, inShiftKey:Bool= false,
         inKeyCode:Int = 0, inDirection:String = "none")
   {
      super(inType,bubbles,cancelable);
      relatedObject = inRelatedObject;
      keyCode = inKeyCode;
      shiftKey = inShiftKey;
   }
}


#end