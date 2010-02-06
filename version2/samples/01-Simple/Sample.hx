import nme2.Manager;
import nme2.events.MouseEvent;
import nme2.events.Event;
import nme2.display.DisplayObject;

class Sample extends nme2.display.Sprite
{

public function new()
{
   super();
   Manager.stage.addChild(this);
   stage.frameRate = 100;

   var gfx = graphics;
   gfx.beginFill(0xff0000);
   gfx.lineStyle(6,0x000000);
   gfx.moveTo(100,100);
   gfx.lineTo(200,100);
   gfx.lineTo(200,200);
   gfx.lineTo(100,200);
   gfx.lineTo(100,100);

   var shape = new nme2.display.Sprite();
   var gfx = shape.graphics;
   gfx.beginFill(0xffff00);
   gfx.lineStyle(6,0x000000);
   gfx.moveTo(0,0);
   gfx.lineTo(100,0);
   gfx.lineTo(100,100);
   gfx.lineTo(0,100);
   gfx.lineTo(0,0);

   shape.x = 50;
   shape.y = 50;

   shape.addEventListener(MouseEvent.MOUSE_MOVE,function(evt) trace(evt.localX+" "+evt.localY));

   stage.addChild(shape);

   var text = new nme2.text.TextField();
   text.text = "Hello";
   stage.addChild(text);

   var fps:Array<Float> = [];
   
   stage.addEventListener(Event.ENTER_FRAME,function(evt) {
      var t0 =  haxe.Timer.stamp();
      fps.push(t0);
      if (fps.length>50)
          fps.pop();
      // trace(" Fps : " + ((fps.length-1)/( fps[fps.length-1] - fps[0] )) );
      var x = shape.x;
      shape.x = x>300 ? 0 : x+1;
      });
}


public static function main()
{
   Manager.init(320,480, Manager.HARDWARE | Manager.RESIZABLE);

   new Sample();

   Manager.mainLoop();

}

}
