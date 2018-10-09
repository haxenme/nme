package nme.events;
#if (!flash)

import nme.display.InteractiveObject;

@:nativeProperty
class FocusEvent extends Event 
{
   static public inline var FOCUS_IN = "focusIn";
   static public inline var FOCUS_OUT = "focusOut";
   static public inline var KEY_FOCUS_CHANGE = "keyFocusChange";
   static public inline var MOUSE_FOCUS_CHANGE = "mouseFocusChange";

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

   public override function clone():Event 
   {
      return new FocusEvent(type, bubbles, cancelable, relatedObject, shiftKey, keyCode);
   }

   public override function toString():String 
   {
      return "[FocusEvent type=" + type + " bubbles=" + bubbles + " cancelable=" + cancelable + " relatedObject=" + relatedObject + " shiftKey=" + shiftKey + " keyCode=" + keyCode + "]";
   }
}

#else
typedef FocusEvent = flash.events.FocusEvent;
#end
