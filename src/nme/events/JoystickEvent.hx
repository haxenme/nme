package nme.events;
#if (!flash)
import nme.ui.GamepadButton;
import nme.ui.GamepadAxis;

@:nativeProperty
class JoystickEvent extends Event 
{
   public static inline var AXIS_MOVE:String = "axisMove";
   public static inline var BALL_MOVE:String = "ballMove";
   public static inline var BUTTON_DOWN:String = "buttonDown";
   public static inline var BUTTON_UP:String = "buttonUp";
   public static inline var HAT_MOVE:String = "hatMove";
   public static inline var DEVICE_ADDED:String = "deviceAdded";
   public static inline var DEVICE_REMOVED:String = "deviceRemoved";


   public var axis(default, null):Array<Float>;
   public var device:Int;
   public var id:Int;
   public var user:Int;
   public var isGamePad:Bool;
   public var x:Float;
   public var y:Float;
   public var z(get, null):Float;
   public var w(get, null):Float;
     
   function get_z() 
   {
      return (axis==null? 0 : axis[2]);
   }  
   function get_w() 
   {
      return (axis==null? 0 : axis[3]);
   }

   public function new(type:String, bubbles:Bool = false, cancelable:Bool = false, device:Int = 0,
                       id:Int = 0, userId:Int = 0, x:Float = 0, y:Float = 0, axis:Array<Float> = null, isGamePad:Bool=false) 
   {
      super(type, bubbles, cancelable);

      this.device = device;
      this.id = id;
      this.user = userId;
      this.axis = axis;
      this.x = x;
      this.y = y;
      this.isGamePad = isGamePad;
   }

   public override function clone():Event 
   {
      return new JoystickEvent(type, bubbles, cancelable, device, id, user, x, y, axis);
   }

   public override function toString():String 
   {
      var buf:StringBuf = new StringBuf();
      buf.add("[JoystickEvent type="); buf.add(type);
      buf.add(" device="); buf.add(device);
      buf.add(" user="); buf.add(user);
      buf.add(" id="); buf.add(id);
      buf.add("("); buf.add(idLabel()); buf.add(")");
      buf.add(" x="); buf.add(x);
      buf.add("]");
      return buf.toString();
   }

   public function idLabel():String
   {
      switch(type)
      {
         case BUTTON_DOWN:
            return GamepadButton.toString(id) + "[pressed]";
         case BUTTON_UP:
            return GamepadButton.toString(id) + "[released]";
         case AXIS_MOVE:
            return GamepadAxis.toString(id)+"[x:" + x + " y:" + y + "]";
         case HAT_MOVE:
            return "HAT_MOVE[x:" + x + " y:" + y + "]";
         case BALL_MOVE:
            return "BALL_MOVE[x:" + x + " y:" + y + "]";
      }
      return "";
   }

}

#end
