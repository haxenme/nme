package nme.ui;

import nme.events.Event;
import nme.events.EventDispatcher;
import nme.events.GameInputEvent;

@:access(nme.ui.GameInputControl)
@:access(nme.ui.GameInputDevice)
class GameInput extends EventDispatcher
{
   public static var isSupported(default, null) = true;
   public static var numDevices(default, null) = 0;

   static var nmeDevices = new Array<GameInputDevice>();
   static var nmeDeviceMap = new Map< {}, GameInputDevice>();
   static var nmeInstances = [];


   public function new()
   {
      super();
      nmeInstances.push(this);

      if (nmeInstances.length==1)
      {
         // TODO : Register callbacks
         //  nmeGamepadConnect
         //  nmeGamepadDisconnect
         //  nmeGamepadButton
         //  nmeGamepadAxisMove
      }
   }


   public override function addEventListener(type:String, listener:Dynamic->Void, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void
   {
      super.addEventListener (type, listener, useCapture, priority, useWeakReference);
      if (type == GameInputEvent.DEVICE_ADDED)
      {
         for (device in nmeDevices)
         {
            dispatchEvent(new GameInputEvent (GameInputEvent.DEVICE_ADDED, device));
         }
      }
   }


   public static function getDeviceAt(index:Int):GameInputDevice
   {
      if (index >= 0 && index < nmeDevices.length)
      {
         return nmeDevices[index];
      }
      return null;
   }

   static function getGamepadGuid(gamepad:Dynamic) : String
   {
      // TODO
      return "guid";
   }


   static function getGamepadName(gamepad:Dynamic) : String
   {
      // TODO
      return "name";
   }

   private static function __getDevice(gamepad:Dynamic):GameInputDevice
   {
      if (gamepad == null) return null;
      if (!nmeDeviceMap.exists(gamepad))
      {
         var device = new GameInputDevice(getGamepadGuid(gamepad), getGamepadName(gamepad));
         nmeDevices.push (device);
         nmeDeviceMap.set(gamepad, device);
         numDevices = nmeDevices.length;
      }

      return nmeDeviceMap.get(gamepad);

   }



   static function nmeGamepadConnect(gamepad:Dynamic):Void
   {
      var device = __getDevice(gamepad);
      if (device == null) return;

      for (instance in nmeInstances)
      {
         instance.dispatchEvent(new GameInputEvent (GameInputEvent.DEVICE_ADDED, device));
      }
   }


   static function nmeGamepadDisconnect(gamepad:Dynamic):Void
   {
      var device = nmeDeviceMap.get(gamepad);
      if (device != null)
      {
         if (nmeDeviceMap.exists(gamepad))
         {
            nmeDevices.remove(nmeDeviceMap.get (gamepad));
            nmeDeviceMap.remove(gamepad);
         }

         numDevices = nmeDevices.length;

         for (instance in nmeInstances)
         {
            instance.dispatchEvent(new GameInputEvent (GameInputEvent.DEVICE_REMOVED, device));
         }
      }
   }




   static function nmeGamepadAxisMove(gamepad:Dynamic, axis:Int, value:Float):Void
   {
      var device = __getDevice(gamepad);
      if (device == null) return;
      if (device.enabled)
      {
         if (!device.nmeAxis.exists(axis))
         {
            var control = new GameInputControl(device, "AXIS_" + axis, -1, 1);
            device.nmeAxis.set(axis, control);
            device.nmeControls.push(control);
         }

         var control = device.nmeAxis.get(axis);
         control.value = value;
         control.dispatchEvent(new Event(Event.CHANGE));
      }
   }


   static function nmeGamepadButton(gamepad:Dynamic, button:Int, down:Int):Void
   {
      var device = __getDevice (gamepad);
      if (device == null) return;

      if (device.enabled)
      {
         if (!device.nmeButton.exists (button))
         {
            var control = new GameInputControl(device, "BUTTON_" + button, 0, 1);
            device.nmeButton.set (button, control);
            device.nmeControls.push(control);
         }

         var control = device.nmeButton.get(button);
         control.value = down;
         control.dispatchEvent(new Event(Event.CHANGE));
      }
   }
}



