import nme.Manager;
import nme.Surface;
import nme.Rect;
import nme.Point;
import nme.TTF;

class DrawSurface
{	
	static var mainObject : DrawSurface;
	var running : Bool;
	var mng : Manager;
	var batSrf : Surface;
	
	static function main()
	{
		mainObject = new DrawSurface();
	}
	
	public function new()
	{
		mng = new Manager( 200, 200, "Surface Draw", false, "ico.gif" );
		batSrf = new Surface( "bat.PNG" );
		batSrf.setKey( 0xFF, 0x00, 0xFF );
			
		var x = 30;
		var y = 30;
		var dir = true;
		running = true;
		while (running)
		{
         mng.events();
         if (mng.getEventType()==et_quit)
            break;
			mng.clear( 0x00000000 );
			
			batSrf.draw( Manager.getScreen(), new Rect(24, 63, 65, 44), new Point( x, y ) );
			if ( dir == true )
				x = y = x + 10;
			else
				x = y = x - 10;
			if ( x > 150 ) dir = false;
			if ( x < 40 ) dir = true;
			
			mng.flip();
			mng.delay( 40 );
		}
		batSrf.free();
		mng.close();
	}
}
