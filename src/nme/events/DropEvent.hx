package nme.events;

import nme.events.Event;
import nme.app.AppEvent;
import nme.geom.Point;
import nme.display.InteractiveObject;

@:nativeProperty
class DropEvent extends MouseEvent
{
   public static var DROP_FILES:String = "dropFiles";

   public var items:Array<String>;


   public static function nmeCreate(inType:String, inEvent:AppEvent, inLocal:Point, inTarget:InteractiveObject, inItems:Array<String>)
   {
      var flags : Int = inEvent.flags;
      var evt = new DropEvent(inType, true, true, inLocal.x, inLocal.y, null,
             (flags & MouseEvent.efCtrlDown) != 0,
             (flags & MouseEvent.efAltDown) != 0,
             (flags & MouseEvent.efShiftDown) != 0,
             (flags & MouseEvent.efLeftDown) != 0, 0, 0);
      evt.stageX = inEvent.x;
      evt.stageY = inEvent.y;
      evt.target = inTarget;
      evt.items = inItems;

      return evt;
   }

   public override function clone():Event
   {
      var e = new DropEvent(type, bubbles, cancelable, localX, localY, relatedObject, ctrlKey, altKey, shiftKey, buttonDown, delta, commandKey, clickCount);
      e.items = items;
      return e;
   }

   public override function toString():String 
   {
      return 'DropEvent($type:$items)';
   }
}

