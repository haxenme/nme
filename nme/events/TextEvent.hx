package nme.events;


#if flash
@:native ("flash.events.TextEvent")
extern class TextEvent extends Event {
	var text : String;
	function new(type : String, bubbles : Bool = false, cancelable : Bool = false, ?text : String) : Void;
	static var LINK : String;
	static var TEXT_INPUT : String;
}
#else



class TextEvent extends Event
{
   public var text(default,null):String;


   public function new(type:String, bubbles:Bool = false, cancelable:Bool = false, inText:String = "")
   {
      super(type,bubbles,cancelable);
      text = inText;
   }
}
#end