import flash.Lib;
import flash.events.MouseEvent;
import flash.events.Event;
import flash.display.DisplayObject;
import flash.display.IGraphicsData;
import flash.display.BitmapData;
import flash.display.Bitmap;
import flash.display.GradientType;
import flash.display.Sprite;
import flash.display.StageDisplayState;
import flash.geom.Matrix;

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
      
   #if neko
   var bd = new BitmapData(100,100,true,flash.display.BitmapData.createColor(0xcccccc,0xcc));
   #else
   var bd = new BitmapData(100,100,true,0xcccccccc);
   #end
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
       case "1".charCodeAt(0):
          stage.quality = flash.display.StageQuality.LOW;
       case "2".charCodeAt(0):
          stage.quality = flash.display.StageQuality.MEDIUM;
       case "3".charCodeAt(0):
          stage.quality = flash.display.StageQuality.HIGH;
       case "4".charCodeAt(0):
          stage.quality = flash.display.StageQuality.BEST;

       #if nme
       case "q".charCodeAt(0): flash.Lib.close();
       #end
       case "f".charCodeAt(0):
          stage.displayState = (stage.displayState==StageDisplayState.NORMAL) ?
              StageDisplayState.FULL_SCREEN : StageDisplayState.NORMAL;
   }
}


public static function main()
{
#if flash
   new Sample();
#else
   Lib.create(function(){new Sample();},320,480,60,0xccccff,(1*Lib.HARDWARE) | Lib.RESIZABLE);
#end
}

}
