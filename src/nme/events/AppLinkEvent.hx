package nme.events;

import nme.events.Event;

@:nativeProperty
class AppLinkEvent extends Event
{
   public static var APP_LINK:String = "appLink";

   public var url:String;

   public function new(type:String, bubbles:Bool = false, cancelable:Bool = false):Void
   {
      super(type, bubbles, cancelable);
   }

   public override function clone():Event
   {
       var e = new AppLinkEvent(type, bubbles, cancelable);
       e.url = url;
       return e;
   }

   public override function toString():String 
   {
      return "[AppLinkEvent type=" + type + " bubbles=" + bubbles + " cancelable=" + cancelable + " url=" + url + "]";
   }
}