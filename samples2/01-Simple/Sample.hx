import nme2.Manager;

class Sample
{

public static function main()
{
   Manager.init(320,480, Manager.HARDWARE | Manager.RESIZABLE);

   var gfx = Manager.stage.graphics;
   gfx.beginFill(0xff0000);
   gfx.lineStyle(6,0x000000);
   gfx.moveTo(100,100);
   gfx.lineTo(200,100);
   gfx.lineTo(200,200);
   gfx.lineTo(100,200);
   gfx.lineTo(100,100);

   var shape = new nme2.display.Shape();
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

   Manager.stage.addChild(shape);

   var text = new nme2.text.TextField();
   text.text = "Hello";
   Manager.stage.addChild(text);
   Manager.mainLoop();
}

}
