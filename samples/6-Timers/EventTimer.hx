import nme.Manager;
import nme.Timer;
import nme.Point;
import nme.TTF;

class EventTimer
{
	static var mainObject : EventTimer;
	var running : Bool;
	static var counter : Float;
	var text : TTF;
	var timer : Timer;
	var mng : Manager;
	
	static function main()
	{
		mainObject = new EventTimer();
	}
	
	public function new()
	{
		mng = new Manager( 200, 200, "Simple Application", false, "ico.gif" );
			
		counter = 0;
		timer = new Timer( 1000 );
		timer.run = function() { counter++; };
		running = true;
                text = new TTF("Counter: ", "../common/ARIAL.TTF",12, 0xffffff,0x000000);
                text.moveTo(15, 15);
		mng.addKeyCallback( processKeys );
		mng.addRenderCallback( processRender );
		mng.mainLoop();
	}
	
	public function processKeys( key : KeyEvent ) : Void
	{
		if ( key.isDown == true && key.code == 27 )
			mng.tryQuit();
		neko.Lib.print( key.code );
	}
	
	public function processRender() : Void
	{
		mng.clear( 0x000000 );
		text.text = Std.string( counter );
        text.draw();
		mng.flip();
	}
}
