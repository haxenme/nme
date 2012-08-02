package;


import haxe.unit.TestRunner;
import nme.display.Sprite;
import tests.nme.display.BitmapTest;
import tests.nme.display.BitmapDataTest;
import tests.nme.display.DisplayObjectTest;
import tests.nme.display.DisplayObjectContainerTest;
import tests.nme.display.GraphicsTest;
import nme.Lib;


/**
 * @author Joshua Granick
 */
class UnitTesting extends Sprite {
	
	
	public function new () {
		
		super ();
		
		fill (0xEEEEEE);
		
		var runner = new TestRunner ();
		
		runner.add (new BitmapTest ());
		runner.add (new BitmapDataTest ());
		runner.add (new DisplayObjectTest ());
		runner.add (new DisplayObjectContainerTest ());
		runner.add (new GraphicsTest ());
		
		var success = runner.run ();
		
		if (success) {
			
			fill (0x00A800);
			
		} else {
			
			fill (0xA80000);
			
		}
		
	}
	
	
	private function fill (color:Int):Void {
		
		graphics.beginFill (color);
		graphics.drawRect (0, 0, Lib.current.stage.stageWidth, Lib.current.stage.stageHeight);
		
	}
	
	
}