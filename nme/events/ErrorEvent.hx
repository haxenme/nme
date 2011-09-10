#if flash


package nme.events;


@:native ("flash.events.ErrorEvent")
extern class ErrorEvent extends TextEvent {
	@:require(flash10_1) var errorID(default,null) : Int;
	function new(type : String, bubbles : Bool = false, cancelable : Bool = false, ?text : String, id : Int = 0) : Void;
	static var ERROR : String;
}



#else


package nme.events;

class ErrorEvent extends TextEvent
{
   public var errorID(default,null):Int;


   public function new(type:String, bubbles:Bool = false, cancelable:Bool = false, text:String = "", inID:Int)
   {
      super(type,bubbles,cancelable,text);
      errorID = inID;
   }

	public override function toString() { return text; }
}


#end