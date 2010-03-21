import nme.Lib;
import nme.events.MouseEvent;
import nme.events.Event;
import nme.display.DisplayObject;
import nme.display.IGraphicsData;

class Sample extends nme.display.Sprite
{

public function new()
{
   super();
   Lib.current.addChild(this);

   var data = nme.display.BitmapData.load("Image.jpg");
   trace(data.width + "x" + data.height);
   addChild( new nme.display.Bitmap(data) );
   var shape = new nme.display.Shape();
   addChild(shape);

	var gfx = shape.graphics;
	gfx.lineStyle(1,0x000000);
	var mtx = new nme.geom.Matrix();
	gfx.beginBitmapFill(data,mtx,true,true);
	gfx.drawRect(0,0,data.width,data.height);

	var mtx = new nme.geom.Matrix();
	mtx.translate(-200,-100);
	mtx.scale(5,5);
	gfx.beginBitmapFill(data,mtx,false,false);
	gfx.drawRect(100,100,200,200);

	shape.x = 100;
	shape.y = 100;

   var data = nme.display.BitmapData.load("Image1.png");
	var mtx = new nme.geom.Matrix();
	mtx.translate(-50,-50);
	gfx.beginBitmapFill(data,mtx,true,true);
	gfx.drawRect(-50,-50,data.width,data.height);

   var shape2 = new nme.display.Shape();
   addChild(shape2);

	var gfx = shape2.graphics;
   var data = nme.display.BitmapData.load("Image2.png");
	var mtx = new nme.geom.Matrix();
	gfx.beginBitmapFill(data,mtx,true,true);
	gfx.drawRect(0,0,data.width,data.height);
	shape2.x = 200;
	shape2.y = 200;



	stage.addEventListener( nme.events.Event.ENTER_FRAME, function(_)
	   {
		   shape.rotation = shape.rotation + 0.01;
		} );

}


public static function main()
{
#if flash
   new Sample();
#else
   Lib.create(function() new Sample(),320,480,60,0xccccff,(1*Lib.HARDWARE) | Lib.RESIZABLE);
#end
}

}
