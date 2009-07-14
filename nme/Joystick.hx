package nme;

class Joystick
{
   var mHandle:Dynamic;

   public var axes(getAxes,null):Int;
   public var hats(getHats,null):Int;
   public var buttons(getButtons,null):Int;
   public var balls(getBalls,null):Int;

   public function new(inID:Int)
   {
      mHandle = nme_joystick_open(inID);
   }

   public static function getList()
   {
      var strings = new Array<String>();
      for(i in 0...nme_joystick_count())
         strings.push( neko.Lib.nekoToHaxe(nme_joystick_name(i)) );
      return strings;
   }

   public function getButton(inID:Int) : Int { return nme_joystick_button(mHandle,inID); }
   public function getAxis(inID:Int) : Float { return nme_joystick_axis(mHandle,inID); }

   public function getAxes() : Int { return nme_joystick_axes(mHandle); }
   public function getButtons() : Int { return nme_joystick_buttons(mHandle); }
   public function getHats() : Int { return nme_joystick_hats(mHandle); }
   public function getBalls() : Int { return nme_joystick_balls(mHandle); }



   static var nme_joystick_count = nme.Loader.load("nme_joystick_count",0);
   static var nme_joystick_name = nme.Loader.load("nme_joystick_name",1);
   static var nme_joystick_open = nme.Loader.load("nme_joystick_open",1);
   static var nme_joystick_axes = nme.Loader.load("nme_joystick_axes",1);
   static var nme_joystick_hats = nme.Loader.load("nme_joystick_hats",1);
   static var nme_joystick_balls = nme.Loader.load("nme_joystick_balls",1);
   static var nme_joystick_buttons = nme.Loader.load("nme_joystick_buttons",1);

   static var nme_joystick_axis = nme.Loader.load("nme_joystick_axis",2);
   static var nme_joystick_button = nme.Loader.load("nme_joystick_button",2);
}
