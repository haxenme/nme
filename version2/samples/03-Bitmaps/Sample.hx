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
   //var bmp = new nme.display.Bitmap(data);
   //addChild(bmp);
	var gfx = graphics;
	gfx.lineStyle(1,0x000000);
	var mtx = new nme.geom.Matrix();
	mtx.translate(-200,-100);
	mtx.scale(5,5);
	gfx.beginBitmapFill(data,mtx,true,true);
	gfx.drawRect(0,0,200,200);

	gfx.beginBitmapFill(data,mtx,false,false);
	gfx.drawRect(100,100,200,200);

	x = 100;
	y = 100;

   var me = this;
	stage.addEventListener( nme.events.Event.ENTER_FRAME, function(_)
	   {
		   me.rotation = me.rotation + 0.01;
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
