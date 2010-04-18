#if flash
import flash.Lib;
import flash.events.MouseEvent;
import flash.display.DisplayObject;
import flash.display.Shape;
import flash.display.Sprite;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.IGraphicsData;
import flash.geom.Matrix;
import flash.events.Event;

import flash.display.CapsStyle;
import flash.display.GradientType;
import flash.display.JointStyle;
import flash.display.SpreadMethod;
import flash.display.LineScaleMode;
import flash.filters.BitmapFilter;
import flash.filters.DropShadowFilter;
#else
import nme.Lib;
import nme.events.MouseEvent;
import nme.display.DisplayObject;
import nme.display.Shape;
import nme.display.Sprite;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.IGraphicsData;
import nme.geom.Matrix;
import nme.events.Event;

import nme.display.CapsStyle;
import nme.display.GradientType;
import nme.display.JointStyle;
import nme.display.SpreadMethod;
import nme.display.LineScaleMode;
import nme.filters.BitmapFilter;
import nme.filters.DropShadowFilter;
#end


class Sample extends Sprite
{

#if neko
   static var zero = haxe.Int32.make(0,0);
#else
   static var zero = 0;
#end

public function new()
{
   super();
   Lib.current.addChild(this);

   var circle = new Sprite();
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
	var f = new Array<BitmapFilter>();
	f.push( new DropShadowFilter() );
	circle.filters = f;

	var shape = new Shape();
	var gfx = shape.graphics;
	gfx.lineStyle(3,0x0000ff);
	gfx.moveTo(5,5);
	gfx.lineTo(25,25);
	var bmp = new BitmapData(32,32,true,zero);
	bmp.draw(shape);
	var bitmap = new Bitmap(bmp);
	bitmap.x = 50;
	bitmap.y = 50;
	addChild(bitmap);

	var combined = new BitmapData(200,200,true,zero);
	var matrix = new Matrix();
	for(x in 0...5)
	   for(y in 0...5)
		{
			matrix.tx = x*20;
			matrix.ty = y*20;
	      combined.draw(bmp,matrix);
		}
	var bitmap = new Bitmap(combined);
	bitmap.x = 150;
	bitmap.y = 50;
	addChild(bitmap);


	stage.addEventListener( Event.ENTER_FRAME, function(_)
	   {
		   circle.rotation = (circle.rotation + 1);
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
