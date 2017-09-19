package nme.events;
#if (!flash)

@:nativeProperty
class JoystickEvent extends Event 
{
   public static inline var AXIS_MOVE:String = "axisMove";
   public static inline var BALL_MOVE:String = "ballMove"; //dummy ballMove for retrocompatibility
   public static inline var BUTTON_DOWN:String = "buttonDown";
   public static inline var BUTTON_UP:String = "buttonUp";
   public static inline var HAT_MOVE:String = "hatMove";
   public static inline var DEVICE_ADDED:String = "deviceAdded";
   public static inline var DEVICE_REMOVED:String = "deviceRemoved";

   public var device:Int;
   public var id:Int;
   public var user:Int;
   public var value:Float;
   public var x(get, set):Float; //x is an alias of "value"
   public var y:Float;
   public var z:Float; //dummy z for retrocompatibility
   public var w:Float; //dummy w for retrocompatibility

   function set_x(inX) {
      return value = inX;
   }
   function get_x() {
      return value;
   }

   public function new(type:String, bubbles:Bool = false, cancelable:Bool = false, device:Int = 0, id:Int = 0, userId:Int = 0, x:Float = 0, y:Float = 0) 
   {
      super(type, bubbles, cancelable);

      this.device = device;
      this.id = id;
      this.user = userId;
      this.value = x;  
      this.y = y; 
   }

   public override function clone():Event 
   {
      return new JoystickEvent(type, bubbles, cancelable, device, id, user, x, y);
   }

   public override function toString():String 
   {
      var buf:StringBuf = new StringBuf();
      buf.add("[JoystickEvent type="); buf.add(type);
      buf.add(" device="); buf.add(device);
      buf.add(" user="); buf.add(user);
      buf.add(" id="); buf.add(id);
      buf.add("("); buf.add(idLabel()); buf.add(")");
      buf.add(" value="); buf.add(value);
      buf.add("]");
      return buf.toString();
   }

   public static inline var BUTTON_A:Int = 0;
   public static inline var BUTTON_B:Int = 1;
   public static inline var BUTTON_X:Int = 2;
   public static inline var BUTTON_Y:Int = 3;
   public static inline var BUTTON_BACK:Int = 4;
   public static inline var BUTTON_GUIDE:Int = 5;
   public static inline var BUTTON_START:Int = 6;
   public static inline var BUTTON_LEFTSTICK:Int = 7;
   public static inline var BUTTON_RIGHTSTICK:Int = 8;
   public static inline var BUTTON_LEFTSHOULDER:Int = 9;
   public static inline var BUTTON_RIGHTSHOULDER:Int = 10;

   //public static inline var BUTTON_DPAD_UP:Int = 11;
   //public static inline var BUTTON_DPAD_DOWN:Int = 12;
   //public static inline var BUTTON_DPAD_LEFT:Int = 13;
   //public static inline var BUTTON_DPAD_RIGHT:Int = 14;

   public static inline var AXIS_LEFTX:Int = 0;
   public static inline var AXIS_LEFTY:Int = 1;
   public static inline var AXIS_RIGHTX:Int = 2;
   public static inline var AXIS_RIGHTY:Int = 3;
   public static inline var AXIS_TRIGGERLEFT:Int = 4;
   public static inline var AXIS_TRIGGERRIGHT:Int = 5;

   private static inline var HAT_UP:Int = 0x1;
   private static inline var HAT_RIGHT:Int = 0x2;
   private static inline var HAT_DOWN:Int = 0x4;
   private static inline var HAT_LEFT:Int = 0x8;

   public function idLabel():String
   {
      switch(type)
      {
         case BUTTON_DOWN, BUTTON_UP:
            switch(id)
            {
               case JoystickEvent.BUTTON_A: return "BUTTON_A";
               case JoystickEvent.BUTTON_B: return "BUTTON_B";
               case JoystickEvent.BUTTON_X: return "BUTTON_X";
               case JoystickEvent.BUTTON_Y: return "BUTTON_Y";
               case JoystickEvent.BUTTON_BACK: return "BUTTON_BACK";
               case JoystickEvent.BUTTON_GUIDE: return "BUTTON_GUIDE";
               case JoystickEvent.BUTTON_START: return "BUTTON_START";
               case JoystickEvent.BUTTON_LEFTSTICK: return "BUTTON_LEFTSTICK";
               case JoystickEvent.BUTTON_RIGHTSTICK: return "BUTTON_RIGHTSTICK";
               case JoystickEvent.BUTTON_LEFTSHOULDER: return "BUTTON_LEFTSHOULDER";
               case JoystickEvent.BUTTON_RIGHTSHOULDER: return "BUTTON_RIGHTSHOULDER";

               //case JoystickEvent.BUTTON_DPAD_UP: return "BUTTON_DPAD_UP";
               //case JoystickEvent.BUTTON_DPAD_DOWN: return "BUTTON_DPAD_DOWN";
               //case JoystickEvent.BUTTON_DPAD_LEFT: return "BUTTON_DPAD_LEFT";
               //case JoystickEvent.BUTTON_DPAD_RIGHT: return "BUTTON_DPAD_RIGHT";
            }
         case AXIS_MOVE:
            switch(id)
            {
               case JoystickEvent.AXIS_LEFTX: return "AXIS_LEFTX";
               case JoystickEvent.AXIS_LEFTY: return "AXIS_LEFTY";
               case JoystickEvent.AXIS_RIGHTX: return "AXIS_RIGHTX";
               case JoystickEvent.AXIS_RIGHTY: return "AXIS_RIGHTY";
               case JoystickEvent.AXIS_TRIGGERLEFT: return "AXIS_TRIGGERLEFT";
               case JoystickEvent.AXIS_TRIGGERRIGHT: return "AXIS_TRIGGERRIGHT";
            }
         case HAT_MOVE:
               return "HAT_MOVE[x:"+x+" y:"+y+"]";
      }
      return "";
   }

}

#end
