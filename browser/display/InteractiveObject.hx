package browser.display;


import browser.geom.Point;


class InteractiveObject extends DisplayObject {
	
	
	public var doubleClickEnabled:Bool;
	public var focusRect:Dynamic;
	public var mouseEnabled:Bool;
	public var tabEnabled:Bool;
	public var tabIndex (get_tabIndex, set_tabIndex):Int;
	
	private var nmeDoubleClickEnabled:Bool;
	private var nmeTabIndex:Int;
	
	
	public function new () {
		
		super ();
		
		tabEnabled = false;
		mouseEnabled = true;
		doubleClickEnabled = true;
		tabIndex = 0;
		
	}
	
	
	override private function nmeGetObjectUnderPoint (point:Point):DisplayObject {
		
		if (!mouseEnabled) {
			
			return null;
			
		} else {
			
			return super.nmeGetObjectUnderPoint (point);
			
		}
		
	}
	
	
	override public function toString ():String {
		
		return "[InteractiveObject name=" + this.name + " id=" + _nmeId + "]";
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	public function get_tabIndex ():Int { return nmeTabIndex; }
	public function set_tabIndex (inIndex:Int):Int { return nmeTabIndex = inIndex; }
	

}