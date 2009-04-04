import nme.Manager;
import nme.Surface;
import nme.Rect;
import nme.Point;
import nme.geom.Matrix;
import nme.display.BitmapData;
import nme.TTF;

/*
  This example is being converted over to use
  the flask-like bitmap drawing api.
  There is still some work to do.
*/

class TransformSurface
{	
	static var mainObject : TransformSurface;
	var running : Bool;
	var mng : Manager;
	var batSrf : BitmapData;
	var dispSrf : BitmapData;
   var sprite: nme.TileRenderer;
	
	static function main()
	{
		mainObject = new TransformSurface();
	}
	
	public function new()
	{
      var opengl = false;
      var args = nme.Sys.args();
      if (args.length>0 && args[0].substr(0,2)=="-o")
         opengl = true;

		mng = new Manager( 200, 200, "Surface Draw", false, "ico.gif", opengl );
		batSrf =  BitmapData.Load( "bat.PNG" );
      sprite = new nme.TileRenderer(batSrf,24,63,65,44,  32,22 );
			
		var dir = true;
		var angle = 0;
      var scale = 1.0;
		running = true;
      var t0 = nme.Time.getSeconds();
		while (running)
		{
         mng.events();
         if (mng.getEventType()==et_quit)
            break;
			mng.clear( 0x00000000 );

         var t_angle = (30*(nme.Time.getSeconds() - t0)) % 360;
         var t_scale = (50*(nme.Time.getSeconds() - t0)) % 360;
         sprite.Blit(100,100,t_angle, 1 + 0.5*Math.cos(t_scale*Math.PI/180.0));
			
			mng.flip();
			mng.delay( 40 );
		}
		mng.close();
	}
}
