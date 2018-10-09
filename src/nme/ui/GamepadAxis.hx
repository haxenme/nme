package nme.ui;
#if (!flash)

@:nativeProperty
class GamepadAxis 
{

   public static inline var LEFT:Int = 0;
   public static inline var RIGHT:Int = 2;
   public static inline var TRIGGER:Int = 4;

   public static function toString(id:Int) : String
   {
      switch(id)
      {
         case GamepadAxis.LEFT: return "GamepadAxis.LEFT";
         case GamepadAxis.RIGHT: return "GamepadAxis.RIGHT";
         case GamepadAxis.TRIGGER: return "GamepadAxis.TRIGGER";
         default: return "AXIS UNKNOWN";
      }
   }
}

#end
