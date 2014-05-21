package nme.events;
#if (cpp || neko)

import nme.net.URLRequestHeader;

class HTTPStatusEvent extends Event 
{
   public static var HTTP_STATUS = "httpStatus";

   public var status:Int;
   public var responseHeaders:Array<URLRequestHeader>;

   public function new(inType:String, bubbles:Bool = false, cancelable:Bool = false, status:Int = 0) 
   {
      super(inType, bubbles, cancelable);

      this.status = status;
      responseHeaders = [];
   }

   public override function clone():Event 
   {
      return new HTTPStatusEvent(type, bubbles, cancelable, status);
   }

   public override function toString():String 
   {
      return "[HTTPStatusEvent type=" + type + " bubbles=" + bubbles + " cancelable=" + cancelable + " status=" + status + "]";
   }
}

#else
typedef HTTPStatusEvent = flash.events.HTTPStatusEvent;
#end
