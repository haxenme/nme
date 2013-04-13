import gm2d.svg.SVG2Gfx;
import nme.display.GradientType;
import nme.display.Sprite;
import nme.filters.DropShadowFilter;
import nme.geom.Matrix;
import nme.Lib;
import sys.io.File;


class Welcome extends Sprite {
	
	
	public function new () {
		
		super ();
		
		createBackground ();
		
		var logo = createLogo ();
		
		logo.filters = [ new DropShadowFilter (5, 45, 0x000000, 0.2, 12, 12) ];
		
		logo.width = 150;
		logo.height = 150;
		
		logo.x = (Lib.current.stage.stageWidth - logo.width) / 2;
		logo.y = 100;
		
		addChild (logo);
		
	}
	
	
	private function createBackground ():Void {
		
		var matrix = new Matrix ();
		matrix.createGradientBox (Lib.current.stage.stageWidth, Lib.current.stage.stageHeight, Math.PI / 2);
		
		graphics.beginGradientFill (GradientType.LINEAR, [ 0xFFFFFF, 0xEEEEEE ], [ 1, 1 ], [ 0, 255 ], matrix);
		graphics.drawRect (0, 0, Lib.current.stage.stageWidth, Lib.current.stage.stageHeight);
		
	}
	
	
	private function createLogo ():Sprite {
		
		var bytes = File.getContent ("assets/nme.svg");
		var xml = Xml.parse (bytes);
		var svg = new SVG2Gfx (xml);
		
		var logo = new Sprite ();
		logo.addChild (svg.CreateShape ());
		
		return logo;
		
	}
	
	
	static function main () {
		
		var onCreate = function () {
			
			Lib.current.addChild (new Welcome ());
			
		}
		
		Lib.create (onCreate, 600, 400, 30, 0xFFFFFF, Lib.HARDWARE, "Welcome");
		
	}
	
	
}