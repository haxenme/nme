package nme.ui;

import nme.events.Event;
import nme.events.EventDispatcher;
import nme.events.GameInputEvent;
import nme.ui.GamepadButton;

@:access(nme.ui.GameInputControl)
@:access(nme.ui.GameInputDevice)
@:allow(nme.display.Stage)
class GameInput extends EventDispatcher
{
   public static var isSupported(default, null) = true;
   public static var numDevices(default, null) = 0;

   static var nmeDevices = new Array<GameInputDevice>();
   static var nmeInstances = [];
   static var nmeKeyboardDevices = new Array<KeyboardInputDevice>();


   public function new()
   {
      super();
      nmeInstances.push(this);

      //Called from Stage
      //if (nmeInstances.length==1)
      //{
         // TODO : Register callbacks
         //  nmeGamepadConnect
         //  nmeGamepadDisconnect
         //  nmeGamepadButton
         //  nmeGamepadAxisMove
      //}
   }

   public function addKeyboardDevice0() : GameInputDevice
   {
      if (nmeKeyboardDevices[0]!=null)
         return nmeKeyboardDevices[0];

      var device = new KeyboardInputDevice("Keyboard0","Keyboard0", [
             GamepadButton.A => Keyboard.SPACE,
             GamepadButton.B => Keyboard.ENTER,
             GamepadButton.X => Keyboard.COMMA,
             GamepadButton.Y => Keyboard.PERIOD,
             GamepadButton.DPAD_UP => Keyboard.UP,
             GamepadButton.DPAD_DOWN => Keyboard.DOWN,
             GamepadButton.DPAD_LEFT => Keyboard.LEFT,
             GamepadButton.DPAD_RIGHT => Keyboard.RIGHT,
             GamepadButton.BACK => Keyboard.ESCAPE,
             GamepadButton.START => Keyboard.TAB,
         ]);
      nmeKeyboardDevices[0] = device;
      dispatchEvent(new GameInputEvent (GameInputEvent.DEVICE_ADDED, device));
      return device;
   }


   static function hasInstances()
   {
      return nmeInstances.length>0 || nmeKeyboardDevices.length>0;
   }


   public override function addEventListener(type:String, listener:Dynamic->Void, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void
   {
      super.addEventListener (type, listener, useCapture, priority, useWeakReference);
      if (type == GameInputEvent.DEVICE_ADDED)
      {
         for (device in nmeDevices)
         {
            if(device!=null)
               dispatchEvent(new GameInputEvent (GameInputEvent.DEVICE_ADDED, device));
         }
         for (device in nmeKeyboardDevices)
         {
            if(device!=null)
               dispatchEvent(new GameInputEvent (GameInputEvent.DEVICE_ADDED, device));
         }
      }
   }

   public static function getBest():GameInputDevice
   {
      for(i in 0...18)
      {
         var d = getDeviceAt(i);
         if (d!=null)
            return d;
      }
      return null;
   }

   public static function getDeviceAt(index:Int):GameInputDevice
   {
      if (index >= 0 && index < nmeDevices.length)
      {
         return nmeDevices[index];
      }
      index -= 16;
      if (index>=0 && index<nmeKeyboardDevices.length)
         return nmeKeyboardDevices[index];
      return null;
   }

   static function getGamepadGuid(index:Int) : String
   {
      // TODO
      return "guid"+index;
   }


   static function getGamepadName(index:Int) : String
   {
      // TODO
      return "name"+index;
   }

   private static function __getDevice(index:Int):GameInputDevice
   {
      if (index < 0 || index > 16) return null;
      if (nmeDevices[index]==null)
      {
         nmeDevices[index] = new GameInputDevice(getGamepadGuid(index), getGamepadName(index));
         numDevices = 0;
         for (nmeDevice in nmeDevices)
         {
            if(nmeDevice!=null)
               numDevices++;
         }
      }

      return nmeDevices[index];

   }


   static function nmeGamepadConnect(index:Int):Void
   {
      var device = __getDevice(index);
      if (device == null) return;

      for (instance in nmeInstances)
      {
         instance.dispatchEvent(new GameInputEvent (GameInputEvent.DEVICE_ADDED, device));
      }
   }


   static function nmeGamepadDisconnect(index:Int):Void
   {
      var device = nmeDevices[index];
      if (device != null)
      {
         nmeDevices[index] = null;
         numDevices = 0;
         for (nmeDevice in nmeDevices)
         {
            if(nmeDevice!=null)
               numDevices++;
         }

         for (instance in nmeInstances)
         {
            instance.dispatchEvent(new GameInputEvent (GameInputEvent.DEVICE_REMOVED, device));
         }
      }
   }




   static function nmeGamepadAxisMove(index:Int, axis:Int, value:Float):Void
   {
      var device = __getDevice(index);
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


   static public function nmeGamepadButton(index:Int, button:Int, down:Int):Void
   {
      var device = __getDevice(index);
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



