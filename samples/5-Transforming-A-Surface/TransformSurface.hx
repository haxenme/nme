import nme.Manager;
import nme.Surface;
import nme.Rect;
import nme.Point;
import nme.TTF;

class TransformSurface
{	
	static var mainObject : TransformSurface;
	var running : Bool;
	var mng : Manager;
	var batSrf : Surface;
	var dispSrf : Surface;
	
	static function main()
	{
		mainObject = new TransformSurface();
	}
	
	public function new()
	{
		mng = new Manager( 200, 200, "Surface Draw", false, "ico.gif" );
		batSrf = new Surface( "bat.png" );
		dispSrf = new Surface( "bat.png" );
		dispSrf.setKey( 0xFF, 0x00, 0xFF );
			
		var dir = true;
		var angle = 0;
		running = true;
		while (running)
		{
			mng.clear( 0x00000000 );
			
			dispSrf.clear( 0xFF00FF );
			batSrf.transform( untyped dispSrf.__srf, angle, new Point(1, 1), new Point(56, 87), new Point(70, 70), Surface.DEFAULT );
			dispSrf.draw( Manager.getScreen(), new Rect(35, 35, 90, 70), new Point( 70, 70 ) );
			
			if ( dir == true )
				angle += 10;
			else
				angle -= 10;
			if ( angle > 350 ) dir = false;
			if ( angle < 10 ) dir = true;
			
			mng.flip();
			mng.delay( 40 );
		}
		batSrf.free();
		mng.close();
	}
}