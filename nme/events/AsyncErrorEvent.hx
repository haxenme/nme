package nme.events;
#if js


import haxe.io.Error;


class AsyncErrorEvent extends ErrorEvent {
	var error:Error;
	function new(type : String, ?bubbles : Bool, ?cancelable : Bool, ?text : String, ?error : Error) : Void
	{
		super(type, bubbles, cancelable);
		this.text = text;
		this.error = error;
	}
	public static var ASYNC_ERROR : String = "nme.events.AsyncErrorEvent";
}


#else
typedef AsyncErrorEvent = flash.errors.AsyncErrorEvent;
#end