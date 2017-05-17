package nme.events;
#if (!flash)

@:nativeProperty
class TextEvent extends Event 
{
   public static inline var LINK:String = "link";
   public static inline var TEXT_INPUT:String = "textInput";

   public var text(default, null):String;

   public function new(type:String, bubbles:Bool = false, cancelable:Bool = false, text:String = "") 
   {
      super(type, bubbles, cancelable);

      this.text = text;
   }

   public override function clone():Event 
   {
      return new TextEvent(type, bubbles, cancelable, text);
   }

   public override function toString():String 
   {
      return "[TextEvent type=" + type + " bubbles=" + bubbles + " cancelable=" + cancelable + " text=" + text + "]";
   }
}

#else
typedef TextEvent = flash.events.TextEvent;
#end
