import nme.Lib;
import nme.events.MouseEvent;
import nme.events.Event;
import nme.display.DisplayObject;
import nme.display.IGraphicsData;
import nme.display.BitmapData;
import nme.display.Bitmap;
import nme.display.GradientType;
import nme.display.Sprite;
import nme.geom.Matrix;

class Sample extends Sprite
{

public function new()
{
   super();
   Lib.current.addChild(this);
   stage.frameRate = 1000;
	var sp = new Sprite();
		sp.graphics.beginFill(0,1);
		sp.graphics.drawCircle(50,50,50);
		sp.graphics.endFill();
		
		var bd = new BitmapData(100,100,true,nme.display.BitmapInt32.make(0xcc,0xcccccc));
		bd.draw(sp);
		
		var bm = new Bitmap(bd);
		this.addChild(bm);
		bm.x = 100;

}


public static function main()
{
#if flash
   new Sample();
#else
   Lib.create(function(){new Sample();},320,480,60,0xccccff,(0*Lib.HARDWARE) | Lib.RESIZABLE);
#end
}

}
