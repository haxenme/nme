package native.display;


import native.geom.ColorTransform;
import native.geom.Matrix;
import native.geom.Rectangle;


interface IBitmapDrawable {	
	
	/** @private */ public function nmeDrawToSurface (inSurface:Dynamic, matrix:Matrix, colorTransform:ColorTransform, blendMode:String, clipRect:Rectangle, smoothing:Bool):Void;
	
}