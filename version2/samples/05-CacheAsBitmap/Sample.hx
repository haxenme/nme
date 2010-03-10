import nme.Lib;
import nme.events.MouseEvent;
import nme.events.Event;
import nme.display.DisplayObject;
import nme.display.IGraphicsData;
import nme.geom.Matrix;

import nme.display.CapsStyle;
import nme.display.GradientType;
import nme.display.JointStyle;
import nme.display.SpreadMethod;
import nme.display.LineScaleMode;


class Sample extends nme.display.Sprite
{

public function new()
{
   super();
   Lib.current.addChild(this);

   var circle = new nme.display.Sprite();
	var gfx = circle.graphics;

   var colours = [ 0xff0000, 0x000000 ];
   var alphas = [ 1.0, 1.0 ];
   var ratios = [ 0, 255 ];
	var mtx = new Matrix();
   // Define positive quadrant ...
   mtx.createGradientBox(100,100, 0, 0,0);
   gfx.beginGradientFill(GradientType.RADIAL,
                       colours, alphas, ratios, mtx, SpreadMethod.REPEAT,
                       -0.9 );
   gfx.drawRect(0,0,100,100);
	addChild(circle);

	circle.cacheAsBitmap = true;
	circle.x = 200;
	circle.y = 200;
	var f = new Array<nme.filters.BitmapFilter>();
	f.push( new nme.filters.BlurFilter(1,1,3) );
	circle.filters = f;

	stage.addEventListener( nme.events.Event.ENTER_FRAME, function(_)
	   {
		   circle.rotation = (circle.rotation + 0.01);
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
