   package nme.ui;
#if (!flash)

@:nativeProperty
class GamepadButton 
{
   public static inline var A:Int = 0;
   public static inline var B:Int = 1;
   public static inline var X:Int = 2;
   public static inline var Y:Int = 3;
#if openfl_legacy
   public static inline var LEFT_SHOULDER:Int = 4;
   public static inline var RIGHT_SHOULDER:Int = 5;
   public static inline var BACK:Int = 6;
   public static inline var START:Int = 7;
   public static inline var LEFT_STICK:Int = 8;
   public static inline var RIGHT_STICK:Int = 9;
   public static inline var GUIDE:Int = 10;
#else
   public static inline var BACK:Int = 4;
   public static inline var GUIDE:Int = 5;
   public static inline var START:Int = 6;
   public static inline var LEFT_STICK:Int = 7;
   public static inline var RIGHT_STICK:Int = 8;
   public static inline var LEFT_SHOULDER:Int = 9;
   public static inline var RIGHT_SHOULDER:Int = 10;
#end
   public static inline var DPAD_UP:Int = 11;
   public static inline var DPAD_DOWN:Int = 12;
   public static inline var DPAD_LEFT:Int = 13;
   public static inline var DPAD_RIGHT:Int = 14;

   public static function toString(id:Int) : String
   {
      switch(id)
      {
         case GamepadButton.A: return "GamepadButton.A";
         case GamepadButton.B: return "GamepadButton.B";
         case GamepadButton.X: return "GamepadButton.X";
         case GamepadButton.Y: return "GamepadButton.Y";
         case GamepadButton.BACK: return "GamepadButton.BACK";
         case GamepadButton.GUIDE: return "GamepadButton.GUIDE";
         case GamepadButton.START: return "GamepadButton.START";
         case GamepadButton.LEFT_STICK: return "GamepadButton.LEFT_STICK";
         case GamepadButton.RIGHT_STICK: return "GamepadButton.RIGHT_STICK";
         case GamepadButton.LEFT_SHOULDER: return "GamepadButton.LEFT_SHOULDER";
         case GamepadButton.RIGHT_SHOULDER: return "GamepadButton.RIGHT_SHOULDER";
         case GamepadButton.DPAD_UP: return "GamepadButton.DPAD_UP";
         case GamepadButton.DPAD_DOWN: return "GamepadButton.DPAD_DOWN";
         case GamepadButton.DPAD_LEFT: return "GamepadButton.DPAD_LEFT";
         case GamepadButton.DPAD_RIGHT: return "GamepadButton.DPAD_RIGHT";
         default: return "BUTTON UNKNOWN[id:"+id+"]";
      }
   }
}

#end
