package nme.ui;

import nme.events.KeyboardEvent;

class KeyboardInputDevice extends GameInputDevice
{
   static var allDevices:Array<KeyboardInputDevice> = null;
   var buttonKeys:Array<Int>;

   public function new(id:String, name:String, inButtonKeys:Map<Int,Int>)
   {
      super(id, name);
      if (allDevices==null)
      {
         allDevices = [];
         nme.Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown );
         nme.Lib.current.stage.addEventListener(KeyboardEvent.KEY_UP, keyUp );
      }
      buttonKeys = [];
      for( bid in inButtonKeys.keys() )
         buttonKeys[bid] = inButtonKeys.get(bid);
      allDevices.push(this);
   }

   function onKey(code:Int, isDown:Bool)
   {
      var bid = buttonKeys.indexOf(code);
      if (bid>=0)
      {
         var but = getButtonAt(bid);
         if (but!=null)
            but.setButtonState(isDown);
      }
   }

   static function keyDown(ev:KeyboardEvent)
   {
      if (ev.keyCode>0)
         for(device in allDevices)
            if (device.enabled)
               device.onKey(ev.keyCode, true);
   }

   static function keyUp(ev:KeyboardEvent)
   {
      if (ev.keyCode>0)
         for(device in allDevices)
            if (device.enabled)
               device.onKey(ev.keyCode, false);
   }
}




