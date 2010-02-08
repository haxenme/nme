package nme.events;

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


   public static var KEY_DOWN = "KEY_DOWN";
   public static var KEY_UP = "KEY_UP";

}

