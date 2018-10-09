package nme.ui;


import nme.utils.ByteArray;

@:access(nme.ui.GameInputControl)
class GameInputDevice
{
   public static var MAX_BUFFER_SIZE = 32000;

   public var enabled:Bool;
   public var id(default, null):String;
   public var name(default, null):String;
   public var numControls(get, never):Int;
   public var sampleInterval:Int;

   var nmeAxis = new Map<Int, GameInputControl> ();
   var nmeButton = new Map<Int, GameInputControl> ();
   var nmeControls = new Array<GameInputControl> ();

   var nmeHandle:Dynamic;


   private function new(id:String, name:String)
   {
      this.id = id;
      this.name = name;
      var control;
      for (i in 0...6)
      {
         control = new GameInputControl(this, "AXIS_" + i, -1, 1);
         nmeAxis.set(i, control);
         nmeControls.push(control);
      }

      for (i in 0...15)
      {
         control = new GameInputControl(this, "BUTTON_" + i, 0, 1);
         nmeButton.set(i, control);
         nmeControls.push(control);
      }
   }

   public function toString() return 'GameInputDevice($id:$name)';

   public function getButtonAt(i:Int) return i>=0 && i<15 ? nmeControls[i+6] : null;

   public function getAxisAt(i:Int) return i>=0 && i<6 ? nmeControls[i] : null;

   public function getCachedSamples(data:ByteArray, append:Bool = false):Int return 0;

   public function isButtonDown(buttonId:Int)
   {
      if (buttonId<0 || buttonId>=15)
         return false;
      return nmeControls[buttonId+6].value>0;
   }

   public function readDPadUp() return isButtonDown(GamepadButton.DPAD_UP);
   public function readDPadDown() return isButtonDown(GamepadButton.DPAD_DOWN);
   public function readDPadLeft() return isButtonDown(GamepadButton.DPAD_LEFT);
   public function readDPadRight() return isButtonDown(GamepadButton.DPAD_RIGHT);

   public function getX0() return nmeControls[0].value;
   public function getY0() return nmeControls[1].value;

   public function isLeft() return getX0()<-0.5 || readDPadLeft();
   public function isRight() return getX0()>0.5 || readDPadRight();
   public function isUp() return getY0()<-0.5 || readDPadUp();
   public function isDown() return getY0()>0.5 || readDPadDown();

   public function getDx() : Int return (isLeft() ? -1 : 0) + (isRight() ? 1 : 0);
   public function getDy() : Int return (isUp() ? -1 : 0) + (isDown() ? 1 : 0);

   public function getControlAt(i:Int):GameInputControl
   {
      if (i >= 0 && i < nmeControls.length)
         return nmeControls[i];
      return null;
   }

   public function startCachingSamples(numSamples:Int, controls:Vector<String>):Void
   {
   }

   public function stopCachingSamples():Void
   {
   }

   function get_numControls():Int
   {
      return nmeControls.length;
   }
}



