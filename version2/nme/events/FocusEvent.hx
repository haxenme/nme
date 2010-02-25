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
