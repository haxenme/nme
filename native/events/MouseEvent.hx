package native.events;


import native.display.InteractiveObject;
import native.geom.Point;


class MouseEvent extends Event {
	
	
	public static var DOUBLE_CLICK:String = "doubleClick";
	public static var CLICK:String = "click";
	public static var MIDDLE_CLICK:String = "middleClick";
	public static var MIDDLE_MOUSE_DOWN:String = "middleMouseDown";
	public static var MIDDLE_MOUSE_UP:String = "middleMouseUp";
	public static var MOUSE_DOWN:String = "mouseDown";
	public static var MOUSE_MOVE:String = "mouseMove";
	public static var MOUSE_OUT:String = "mouseOut";
	public static var MOUSE_OVER:String = "mouseOver";
	public static var MOUSE_UP:String = "mouseUp";
	public static var MOUSE_WHEEL:String = "mouseWheel";
	public static var RIGHT_CLICK:String = "rightClick";
	public static var RIGHT_MOUSE_DOWN:String = "rightMouseDown";
	public static var RIGHT_MOUSE_UP:String = "rightMouseUp";
	public static var ROLL_OUT:String = "rollOut";
	public static var ROLL_OVER:String = "rollOver";
	
	public var altKey:Bool;
	public var buttonDown:Bool;
	public var clickCount:Int;
	public var commandKey:Bool;
	public var ctrlKey:Bool;
	public var delta:Int;
	public var localX:Float;
	public var localY:Float;
	public var relatedObject:InteractiveObject;
	public var shiftKey:Bool;
	public var stageX:Float;
	public var stageY:Float;
	
	private static var efLeftDown = 0x0001;
	private static var efShiftDown = 0x0002;
	private static var efCtrlDown = 0x0004;
	private static var efAltDown = 0x0008;
	private static var efCommandDown = 0x0010;
	
	
	public function new (type:String, bubbles:Bool = true, cancelable:Bool = false, localX:Float = 0, localY:Float = 0, relatedObject:InteractiveObject = null, ctrlKey:Bool = false, altKey:Bool = false, shiftKey:Bool = false, buttonDown:Bool = false, delta:Int = 0, commandKey:Bool = false, clickCount:Int = 0) {
		
		super (type, bubbles, cancelable);
		
		this.localX = localX;
		this.localY = localY;
		this.relatedObject = relatedObject;
		this.ctrlKey = ctrlKey;
		this.altKey = altKey;
		this.shiftKey = shiftKey;
		this.buttonDown = buttonDown;
		this.delta = delta;
		this.commandKey = commandKey;
		this.clickCount = clickCount;
		
	}
	
	
	public override function clone ():Event {
		
		return new MouseEvent (type, bubbles, cancelable, localX, localY, relatedObject, ctrlKey, altKey, shiftKey, buttonDown, delta, commandKey, clickCount);
		
	}
	
	
	/** @private */ public static function nmeCreate (inType:String, inEvent:Dynamic, inLocal:Point, inTarget:InteractiveObject) {
		
		var flags : Int = inEvent.flags;
		var evt = new MouseEvent (inType, true, false, inLocal.x, inLocal.y, null, (flags & efCtrlDown) != 0, (flags & efAltDown) != 0, (flags & efShiftDown) != 0, (flags & efLeftDown) != 0, 0, 0);
		evt.stageX = inEvent.x;
		evt.stageY = inEvent.y;
		evt.target = inTarget;
		return evt;
		
	}
	
	
	/** @private */ public function nmeCreateSimilar (inType:String, ?related:InteractiveObject, ?targ:InteractiveObject) {
		
		var result = new MouseEvent (inType, bubbles, cancelable, localX, localY, related == null ? relatedObject : related, ctrlKey, altKey, shiftKey, buttonDown, delta, commandKey, clickCount);
		
		result.stageX = stageX;
		result.stageY = stageY;
		
		if (targ != null)
			result.target = targ;
		
		return result;
		
	}
	
	
	public override function toString ():String {
		
		return "[MouseEvent type=" + type + " bubbles=" + bubbles + " cancelable=" + cancelable + " localX=" + localX + " localY=" + localY + " relatedObject=" + relatedObject + " ctrlKey=" + ctrlKey + " altKey=" + altKey + " shiftKey=" + shiftKey + " buttonDown=" + buttonDown + " delta=" + delta + "]";
		
	}
	
	
	public function updateAfterEvent () {
		
		
		
	}
	
	
}