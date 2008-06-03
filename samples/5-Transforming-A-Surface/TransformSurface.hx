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
	
	static function main()
	{
		mainObject = new TransformSurface();
	}
	
	public function new()
	{
		mng = new Manager( 200, 200, "Surface Draw", false, "ico.gif" );
		batSrf =  BitmapData.Load( "bat.png" );
		dispSrf = new BitmapData(batSrf.width, batSrf.height);
			
		var dir = true;
		var angle = 0;
		running = true;
		while (running)
		{
			mng.clear( 0x00000000 );

                        var m = new Matrix();
                        m.translate(-70,-70);
                        m.rotate(angle*Math.PI/180.0);
                        m.translate(70,70);

                        var gfx = dispSrf.graphics;
                        gfx.beginBitmapFill(batSrf,m,false,false);
                        gfx.drawRect(0,0,dispSrf.width,dispSrf.height);


                        Manager.graphics.moveTo(1,1);
                        Manager.graphics.blit(dispSrf);
			
			if ( dir == true )
				angle += 10;
			else
				angle -= 10;
			if ( angle > 350 ) dir = false;
			if ( angle < 10 ) dir = true;
			
			mng.flip();
			mng.delay( 40 );
		}
		mng.close();
	}
}
