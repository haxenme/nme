package org.haxenme.unittesting;


import haxe.unit.TestRunner;
import nme.display.Sprite;
import nme.display.StageAlign;
import nme.display.StageScaleMode;
import nme.Lib;
import org.haxenme.unittesting.tests.MathTest;


/**
 * @author Joshua Granick
 */
class UnitTesting extends Sprite {
	
	
	public function new () {
		
		super ();
		
		initialize ();
		
		var runner = new TestRunner ();
		
		runner.add (new MathTest ());
		
		runner.run ();
		
	}
	
	
	private function initialize ():Void {
		
		Lib.current.stage.align = StageAlign.TOP_LEFT;
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		
	}
	
	
	
	
	// Entry point
	
	
	
	
	public static function main () {
		
		Lib.current.addChild (new UnitTesting ());
		
	}
	
	
}