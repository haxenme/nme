   package nme.ui;
#if (!flash)

@:nativeProperty
class GamepadButton 
{
   public static inline var A:Int = 0;
   public static inline var B:Int = 1;
   public static inline var X:Int = 2;
   public static inline var Y:Int = 3;
   public static inline var BACK:Int = 4;
   public static inline var GUIDE:Int = 5;
   public static inline var START:Int = 6;
   public static inline var LEFTSTICK:Int = 7;
   public static inline var RIGHTSTICK:Int = 8;
   public static inline var LEFTSHOULDER:Int = 9;
   public static inline var RIGHTSHOULDER:Int = 10;

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
         case GamepadButton.LEFTSTICK: return "GamepadButton.LEFTSTICK";
         case GamepadButton.RIGHTSTICK: return "GamepadButton.RIGHTSTICK";
         case GamepadButton.LEFTSHOULDER: return "GamepadButton.LEFTSHOULDER";
         case GamepadButton.RIGHTSHOULDER: return "GamepadButton.RIGHTSHOULDER";
         default: return "BUTTON UNKNOWN[id:"+id+"]";
      }
   }
}

#end
