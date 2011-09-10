#if flash


package nme.events;


@:native ("flash.events.MouseEvent")
extern class MouseEvent extends Event {
	var altKey : Bool;
	var buttonDown : Bool;
	var ctrlKey : Bool;
	var delta : Int;
	@:require(flash10) var isRelatedObjectInaccessible : Bool;
	var localX : Float;
	var localY : Float;
	var relatedObject : flash.display.InteractiveObject;
	var shiftKey : Bool;
	var stageX(default,null) : Float;
	var stageY(default,null) : Float;
	function new(type : String, bubbles : Bool = true, cancelable : Bool = false, ?localX : Float, ?localY : Float, ?relatedObject : flash.display.InteractiveObject, ctrlKey : Bool = false, altKey : Bool = false, shiftKey : Bool = false, buttonDown : Bool = false, delta : Int = 0) : Void;
	function updateAfterEvent() : Void;
	static var CLICK : String;
	static var DOUBLE_CLICK : String;
	static var MOUSE_DOWN : String;
	static var MOUSE_MOVE : String;
	static var MOUSE_OUT : String;
	static var MOUSE_OVER : String;
	static var MOUSE_UP : String;
	static var MOUSE_WHEEL : String;
	static var ROLL_OUT : String;
	static var ROLL_OVER : String;
}



#else


package nme.events;

import nme.display.InteractiveObject;
import nme.geom.Point;

class MouseEvent extends nme.events.Event
{
   public var localX : Float;
   public var localY : Float;
   public var relatedObject : InteractiveObject;
   public var ctrlKey : Bool;
   public var altKey : Bool;
   public var shiftKey : Bool;
   public var buttonDown : Bool;
   public var delta : Int;
   public var commandKey : Bool;
   public var clickCount : Int;

   public var stageX : Float;
   public var stageY : Float;

   public function new(type : String,
            bubbles : Bool = true, 
            cancelable : Bool = false,
            in_localX : Float = 0,
            in_localY : Float = 0,
            in_relatedObject : InteractiveObject = null,
            in_ctrlKey : Bool = false,
            in_altKey : Bool = false,
            in_shiftKey : Bool = false,
            in_buttonDown : Bool = false,
            in_delta : Int = 0,
            in_commandKey:Bool = false,
            in_clickCount:Int = 0 )
   {
      super(type,bubbles,cancelable);

      localX = in_localX;
      localY = in_localY;
      relatedObject = in_relatedObject;
      ctrlKey = in_ctrlKey;
      altKey = in_altKey;
      shiftKey = in_shiftKey;
      buttonDown = in_buttonDown;
      delta = in_delta;
      commandKey = in_commandKey;
      clickCount = in_clickCount;
   }

   static var efLeftDown  =  0x0001;
   static var efShiftDown =  0x0002;
   static var efCtrlDown  =  0x0004;
   static var efAltDown   =  0x0008;
   static var efCommandDown = 0x0010;

   public static function nmeCreate(inType:String, inEvent:Dynamic,inLocal:Point,
	   inTarget:InteractiveObject)
   {
      var flags : Int = inEvent.flags;
      var evt = new MouseEvent(inType, true, false, inLocal.x, inLocal.y, null,
           (flags & efCtrlDown) != 0,
           (flags & efAltDown) != 0,
           (flags & efShiftDown) != 0,
           (flags & efLeftDown) != 0,
           0,0 );
      evt.stageX = inEvent.x;
      evt.stageY = inEvent.y;
		evt.target = inTarget;
      return evt;
   }

   public function nmeCreateSimilar(inType:String,
	     ?related:InteractiveObject,?targ:InteractiveObject)
	{
		var result = new MouseEvent(inType,bubbles,cancelable,localX,localY,
			related==null ? relatedObject : related,
			ctrlKey, altKey, shiftKey, buttonDown, delta, commandKey, clickCount );

		if (targ!=null)
			result.target = targ;
		return result;
	}

   public function updateAfterEvent()
   {
   }

   public static var MOUSE_MOVE : String = "mouseMove";
   public static var MOUSE_OUT : String = "mouseOut";
   public static var MOUSE_OVER : String = "mouseOver";
   public static var ROLL_OUT : String = "rollOut";
   public static var ROLL_OVER : String = "rollOver";

   public static var CLICK : String = "click";
   public static var MOUSE_DOWN : String = "mouseDown";
   public static var MOUSE_UP : String = "mouseUp";

   public static var MIDDLE_CLICK : String = "middleClick";
   public static var MIDDLE_MOUSE_DOWN : String = "middleMouseDown";
   public static var MIDDLE_MOUSE_UP : String = "middleMouseUp";

   public static var RIGHT_CLICK : String = "rightClick";
   public static var RIGHT_MOUSE_DOWN : String = "rightMouseDown";
   public static var RIGHT_MOUSE_UP : String = "rightMouseUp";

   public static var MOUSE_WHEEL : String = "mouseWheel";
   public static var DOUBLE_CLICK : String = "doubleClick";
}


#end