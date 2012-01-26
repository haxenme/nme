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
	
	public var id:Int;
	public var relativeX:Float;
	public var relativeY:Float;
	public var value:Float;
	
	
	public function new(type:String, bubbles:Bool = false, cancelable:Bool = false, id:Int = 0)
	{	
		super (type, bubbles, cancelable);
		
		this.id = id;
	}
	
	
	public override function clone():Event
	{
		return new JoystickEvent (type, bubbles, cancelable, id);
	}
	
	
	public override function toString():String
	{
		var result = "[JoystickEvent type=" + type + " bubbles=" + bubbles + " cancelable=" + cancelable + " id=" + id;
		
		if (type == AXIS_MOVE)
		{
			result += " value=" + value;
		}
		else if (type == BALL_MOVE)
		{
			result += " relativeX=" + relativeX + " relativeY=" + relativeY;
		}
		
		result += "]";
		
		return result;
	}
	
	
}