package;


import haxe.unit.TestRunner;
import nme.display.Sprite;
import tests.nme.display.BitmapTest;
import tests.nme.display.BitmapDataTest;
import tests.nme.display.DisplayObjectTest;
import tests.nme.display.DisplayObjectContainerTest;
import tests.nme.display.GraphicsTest;
import tests.nme.utils.ByteArrayTest;
import nme.Lib;


/**
 * @author Joshua Granick
 */
class UnitTesting extends Sprite {
	
	
	public function new () {
		
		super ();
		
		#if js
		var div = js.Lib.document.createElement ("div");
		div.id = "haxe:trace";
		div.style.position = "absolute";
		div.style.top = (Lib.current.stage.stageHeight + 10) + "px";
		div.style.left = "10px";
		div.style.width = (Lib.current.stage.stageWidth - 20) + "px";
		div.style.fontFamily = "Helvetica, Arial, sans-serif";
		div.style.fontSize = "14px";
		js.Lib.document.body.appendChild (div);
		#end
		
		fill (0xEEEEEE);

		var runner:TestRunner = new TestRunner ();
		
		#if flash
		TestRunner.print("Flash Version: " + flash.system.Capabilities.version + "\n\n");
		#end
		
		runner.add (new BitmapTest ());
		runner.add (new BitmapDataTest ());
		runner.add (new DisplayObjectTest ());
		runner.add (new DisplayObjectContainerTest ());
		runner.add (new GraphicsTest ());
		
		runner.add (new ByteArrayTest ());
		
		
		var success = runner.run ();
		
		if (success) {
			
			fill (0x00A800);
			
		} else {
			
			fill (0xA80000);
			
		}
		
	}
	
	
	private function fill (color:Int):Void {
		
		Lib.current.graphics.beginFill (color);
		Lib.current.graphics.drawRect (0, 0, Lib.current.stage.stageWidth, Lib.current.stage.stageHeight);
		
	}
	
	
}