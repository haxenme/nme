package browser.geom;


import browser.display.DisplayObject;


class Transform {
	
	
	public static var DEG_TO_RAD:Float = Math.PI / 180.0;
	
	public var colorTransform (default, set_colorTransform):ColorTransform;
	public var matrix (get_matrix, set_matrix):Matrix;
	public var pixelBounds (get_pixelBounds, never):Rectangle;
	
	private var _displayObject:DisplayObject;
	private var _fullMatrix:Matrix;
	private var _matrix:Matrix;
	
	
	public function new (displayObject:DisplayObject) {
		
		if (displayObject == null) throw "Cannot create Transform with no DisplayObject.";
		_displayObject = displayObject;
		
		_matrix = new Matrix ();
		_fullMatrix = new Matrix ();
		this.colorTransform = new ColorTransform ();
		
	}
	
	
	public inline function nmeGetFullMatrix (localMatrix:Matrix = null):Matrix {
		
		var m;
		
		if (localMatrix != null) {
			
			m = localMatrix.mult (_fullMatrix);
			
		} else {
			
			m = _fullMatrix.clone ();
			
		}
		
		return m;
		
	}
	
	
	public inline function nmeSetFullMatrix (inValue:Matrix):Matrix {
		
		_fullMatrix.copy (inValue);
		return _fullMatrix;
		
	}
	
	
	public inline function nmeSetMatrix (inValue:Matrix):Void {
		
		_matrix.copy (inValue);
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function set_colorTransform (inValue:ColorTransform):ColorTransform {
		
		this.colorTransform = inValue;
		return inValue;
		
	}
	
	
	private function get_matrix ():Matrix {
		
		return _matrix.clone ();
		
	}
	
	
	private function set_matrix (inValue:Matrix):Matrix {
		
		nmeSetMatrix (inValue);
		_displayObject.nmeMatrixOverridden ();
		return _matrix;
		
	}
	
	
	private function get_pixelBounds ():Rectangle {
		
		return _displayObject.getBounds (null);
		
	}
	
	
}