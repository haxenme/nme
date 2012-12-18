package browser.display;


import browser.display.Graphics;
import browser.display.InteractiveObject;
import browser.geom.Matrix;
import browser.geom.Point;
import browser.Lib;


class Shape extends DisplayObject {
	
	
	public var graphics (get_graphics, never):Graphics;
	
	private var nmeGraphics:Graphics;
	
	
	public function new () {
		
		super ();
		
		nmeGraphics = new Graphics ();
		
	}
	
	
	public override function nmeGetGraphics ():Graphics {
		
		return nmeGraphics;
		
	}
	
	
	override public function nmeGetObjectUnderPoint (point:Point):DisplayObject {
		
		if (parent == null) return null;
		
		if (parent.mouseEnabled && super.nmeGetObjectUnderPoint (point) == this) {
			
			return parent;
			
		} else {
			
			return null;
			
		}
		
	}
	
	
	override public function toString ():String {
		
		return "[Shape name=" + this.name + " id=" + _nmeId + "]";
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function get_graphics ():Graphics {
		
		return nmeGraphics;
		
	}
	
	
}