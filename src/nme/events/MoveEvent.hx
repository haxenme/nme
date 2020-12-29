package nme.events;

import nme.events.Event;
import nme.app.AppEvent;
import nme.geom.Point;
import nme.display.InteractiveObject;

@:nativeProperty
class MoveEvent extends Event
{
   public var x:Int;
   public var y:Int;

   public static var WINDOW_MOVED:String = "windowMoved";

   public function new(type:String, bubbles:Bool = true, cancelable:Bool = false, inX:Int = 0, inY:Int = 0)
   {
      super(type, bubbles, cancelable);
      x = inX;
      y = inY;
   }

   public override function clone():Event
   {
      var e = new MoveEvent(type, bubbles, cancelable, x, y);
      return e;
   }

   public override function toString():String 
   {
      return 'MoveEvent($type,$x,$y)';
   }
}


