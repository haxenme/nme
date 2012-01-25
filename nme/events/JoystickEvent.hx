package nme.events;


class JoystickEvent extends Event
{
	
	public static var AXIS_MOVE:String = "axisMove";
	public static var BALL_MOVE:String = "ballMove";
	public static var BUTTON_DOWN:String = "buttonDown";
	public static var BUTTON_UP:String = "buttonUp";
	public static var HAT_CENTER:String = "hatCenter";
	public static var HAT_DOWN:String = "hatDown";
	public static var HAT_LEFT:String = "hatLeft";
	public static var HAT_RIGHT:String = "hatRight";
	public static var HAT_UP:String = "hatUp";
	
	public var index:Int;
	public var position:Float;
	public var relativeX:Float;
	public var relativeY:Float;
	
	
	public function new(type:String, bubbles:Bool = false, cancelable:Bool = false, index:Int = 0)
	{	
		super (type, bubbles, cancelable);
		
		this.index = index;
	}
	
	
	public override function clone():Event
	{
		return new JoystickEvent (type, bubbles, cancelable, index);
	}
	
	
	public override function toString():String
	{
		return "[JoystickEvent type=" + type + " bubbles=" + bubbles + " cancelable=" + cancelable + " index=" + index + "]";
	}
	
	
}