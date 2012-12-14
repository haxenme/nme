package native.geom;


import native.display.DisplayObject;


class Transform {
	
	
	public var colorTransform (get_colorTransform, set_colorTransform):ColorTransform;
	public var concatenatedColorTransform (get_concatenatedColorTransform, null):ColorTransform;
	public var concatenatedMatrix (get_concatenatedMatrix, null):Matrix;
	public var matrix (get_matrix, set_matrix):Matrix;
	public var pixelBounds (get_pixelBounds, null):Rectangle;
	
	/** @private */ private var nmeObj:DisplayObject;
	
	
	public function new (inParent:DisplayObject) {
		
		nmeObj = inParent;
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function get_colorTransform ():ColorTransform { return nmeObj.nmeGetColorTransform (); }
	private function set_colorTransform (inTrans:ColorTransform):ColorTransform { nmeObj.nmeSetColorTransform (inTrans); return inTrans; }
	private function get_concatenatedColorTransform ():ColorTransform { return nmeObj.nmeGetConcatenatedColorTransform (); }
	private function get_concatenatedMatrix ():Matrix { return nmeObj.nmeGetConcatenatedMatrix (); }
	private function get_matrix ():Matrix { return nmeObj.nmeGetMatrix (); }
	private function set_matrix (inMatrix:Matrix):Matrix { nmeObj.nmeSetMatrix (inMatrix); return inMatrix; }
	private function get_pixelBounds ():Rectangle { return nmeObj.nmeGetPixelBounds (); }
	
	
}