package nme.events;


#if flash
@:native ("flash.events.KeyboardEvent")
extern class KeyboardEvent extends Event {
	var altKey : Bool;
	var charCode : UInt;
	var ctrlKey : Bool;
	var keyCode : UInt;
	var keyLocation : nme.ui.KeyLocation;
	var shiftKey : Bool;
	function new(type : String, bubbles : Bool = true, cancelable : Bool = false, charCodeValue : UInt = 0, keyCodeValue : UInt = 0, keyLocationValue : nme.ui.KeyLocation = 0, ctrlKeyValue : Bool = false, altKeyValue : Bool = false, shiftKeyValue : Bool = false) : Void;
	function updateAfterEvent() : Void;
	static var KEY_DOWN : String;
	static var KEY_UP : String;
}
#else



class KeyboardEvent extends nme.events.Event
{
   public var keyCode : Int;
   public var charCode : Int;
   public var keyLocation : Int;

   public var ctrlKey : Bool;
   public var altKey : Bool;
   public var shiftKey : Bool;


   public function new(type : String, ?bubbles : Bool, ?cancelable : Bool,
         ?inCharCode : Int, ?inKeyCode : Int, ?inKeyLocation : Int,
         ?inCtrlKey : Bool, ?inAltKey : Bool, ?inShiftKey : Bool)
   {
      super(type,bubbles,cancelable);

      keyCode = inKeyCode;
      keyLocation = inKeyLocation==null ? 0 : inKeyLocation;
      charCode = inCharCode==null ? 0 : inCharCode;

      shiftKey = inShiftKey==null ? false : inShiftKey;
      altKey = inAltKey==null ? false : inAltKey;
      ctrlKey = inCtrlKey==null ? false : inCtrlKey;
   }


   public static var KEY_DOWN = "keyDown";
   public static var KEY_UP = "keyUp";

}
#end