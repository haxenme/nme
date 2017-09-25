package nme.ui;


import nme.events.EventDispatcher;


class GameInputControl extends EventDispatcher
{
   public var device(default, null):GameInputDevice;
   public var id(default, null):String;
   public var maxValue(default, null):Float;
   public var minValue(default, null):Float;
   public var value(default, null):Float;

   private function new(inDevice:GameInputDevice, inId:String, inMinValue:Float, inMaxValue:Float, inValue:Float = 0)
   {
      super ();
      device = inDevice;
      id = inId;
      minValue = inMinValue;
      maxValue = inMaxValue;
      value = inValue;
   }
}



