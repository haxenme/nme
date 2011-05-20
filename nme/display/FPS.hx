package nme.display;

class FPS extends nme.text.TextField
{
   var times:Array<Float>;

   public function new(inX:Float=10.0, inY:Float=10.0, inCol:Int = 0x000000)
   {
      super();
      x = inX;
      y = inY;
      selectable = false;
      text = "FPS:";
      textColor = inCol;
      times = [];
      addEventListener(nme.events.Event.ENTER_FRAME, onEnter);
   }

   public function onEnter(_)
   {
      var now = nme.Timer.stamp();
      times.push(now);
      while(times[0]<now-1)
         times.shift();
      if (visible)
      {
         text = "FPS:" + times.length;
      }
   }

}
