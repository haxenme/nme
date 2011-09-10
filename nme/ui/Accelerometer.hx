package nme.ui;


#if !flash
class Accelerometer
{
   // returns null if device not supported
   public static function get() : Acceleration
   {
      return nme_input_get_acceleration();
   }

   static var nme_input_get_acceleration = nme.Loader.load("nme_input_get_acceleration",0);
}
#end