package nme.events;

#if (cpp||neko)

class AsyncErrorEvent extends ErrorEvent
{
	public static var ASYNC_ERROR  = "asyncError";
   public var error : nme.errors.Error;

	public function new(type : String, bubbles : Bool = false, cancelable : Bool = false, ?text : String, ?inError : nme.errors.Error)
   {
      super(type,bubbles,cancelable,text, inError==null ? inError.errorID : 0);
      error = inError;
   }
}


#else
typedef AsyncErrorEvent = flash.events.AsyncErrorEvent;
#end
