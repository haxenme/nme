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

   public function getCachedSamples(data:ByteArray, append:Bool = false):Int return 0;

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



