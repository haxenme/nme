import nme.Lib;
import nme.events.MouseEvent;
import nme.events.Event;
import nme.display.DisplayObject;
import nme.display.IGraphicsData;
import nme.display.BitmapData;
import nme.display.Bitmap;
import nme.display.GradientType;
import nme.display.Sprite;
import nme.display.StageDisplayState;
import nme.geom.Matrix;

class Sample extends Sprite
{

public function new()
{
   super();
   Lib.current.addChild(this);
   #if nme
   Lib.current.addChild(new nme.display.FPS() );
   #end
   var sp = new Sprite();
   sp.graphics.beginFill(0,1);
   sp.graphics.drawCircle(50,50,50);
   sp.graphics.endFill();

   stage.frameRate = 60;
      
   var bd = new BitmapData(100,100,true,0xcccccccc);
   bd.draw(sp);
      
   var bm = new Bitmap(bd);
   this.addChild(bm);
   bm.x = 100;

   var shape = new Sprite();
   var gfx = shape.graphics;
   gfx.lineStyle(1,0xff0000);
   gfx.beginFill(0xffffff);
   gfx.drawRect(0,0,20,40);
   shape.x = 100;
   shape.y = 100;
   shape.rotation = 10;
   addChild(shape);


   stage.addEventListener(flash.events.KeyboardEvent.KEY_DOWN, OnKey );

   stage.addEventListener(Event.ENTER_FRAME, function(_) { shape.rotation+=360/60/60; } );
   stage.addEventListener(MouseEvent.MOUSE_MOVE, function(e:MouseEvent) {
      trace("Hit : " + e.stageX + "," + e.stageY + " : " +
          shape.hitTestPoint( e.stageX, e.stageY, false ) );
   });
}

function OnKey(event)
{
   switch(event.charCode)
   {
       case "1".code:
          stage.quality = flash.display.StageQuality.LOW;
       case "2".code:
          stage.quality = flash.display.StageQuality.MEDIUM;
       case "3".code:
          stage.quality = flash.display.StageQuality.HIGH;
       case "4".code:
          stage.quality = flash.display.StageQuality.BEST;
       case "f".code:
          stage.displayState = (stage.displayState==StageDisplayState.NORMAL) ?
              StageDisplayState.FULL_SCREEN : StageDisplayState.NORMAL;
   }
}


public static function main()
{
   new Sample();
}

}
