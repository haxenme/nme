package native.events;


import native.display.InteractiveObject;
import native.geom.Point;


class TouchEvent extends MouseEvent {
	
	
	public static var TOUCH_BEGIN:String = "touchBegin";
	public static var TOUCH_END:String = "touchEnd";
	public static var TOUCH_MOVE:String = "touchMove";
	public static var TOUCH_OUT:String = "touchOut";
	public static var TOUCH_OVER:String = "touchOver";
	public static var TOUCH_ROLL_OUT:String = "touchRollOut";
	public static var TOUCH_ROLL_OVER:String = "touchRollOver";
	public static var TOUCH_TAP:String = "touchTap";
	
	public var isPrimaryTouchPoint:Bool;
	public var touchPointID:Int;
	
	public var sizeX:Float;
	public var sizeY:Float;
	
	
	public function new (type:String, bubbles:Bool = true, cancelable:Bool = false, in_localX:Float = 0, in_localY:Float = 0, in_sizeX:Float = 1, in_sizeY:Float = 1, in_relatedObject:InteractiveObject = null, in_ctrlKey:Bool = false, in_altKey:Bool = false, in_shiftKey:Bool = false, in_buttonDown:Bool = false, in_delta:Int = 0, in_commandKey:Bool = false, in_clickCount:Int = 0) {
		
		super (type, bubbles, cancelable, in_localX, in_localY, in_relatedObject, in_ctrlKey, in_altKey, in_shiftKey, in_buttonDown, in_delta, in_commandKey, in_clickCount);
		
		touchPointID = 0;
		isPrimaryTouchPoint = true;
		sizeX = in_sizeX;
		sizeY = in_sizeY;
		
	}
	
	
	public static function nmeCreate (inType:String, inEvent:Dynamic, inLocal:Point, inTarget:InteractiveObject, sizeX:Float, sizeY:Float) {
		
		var flags : Int = inEvent.flags;
		var evt = new TouchEvent (inType, true, false, inLocal.x, inLocal.y, sizeX, sizeY, null, (flags & MouseEvent.efCtrlDown) != 0, (flags & MouseEvent.efAltDown) != 0, (flags & MouseEvent.efShiftDown) != 0, (flags & MouseEvent.efLeftDown) != 0, 0, 0);
		evt.stageX = inEvent.x;
		evt.stageY = inEvent.y;
		evt.target = inTarget;
		return evt;
		
	}
	
	
	override public function nmeCreateSimilar (inType:String, ?related:InteractiveObject, ?targ:InteractiveObject):MouseEvent {
		
		var result = new TouchEvent (inType, bubbles, cancelable, localX, localY, sizeX, sizeY, related == null ? relatedObject : related, ctrlKey, altKey, shiftKey, buttonDown, delta, commandKey, clickCount);
		
		result.touchPointID = touchPointID;
		result.isPrimaryTouchPoint = isPrimaryTouchPoint;
		if (targ != null)
			result.target = targ;
		return result;
		
	}
	
	
}