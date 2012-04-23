package neash.display;


import neash.geom.ColorTransform;
import neash.geom.Matrix;
import neash.geom.Rectangle;


interface IBitmapDrawable
{	
	
	/** @private */ public function nmeDrawToSurface(inSurface:Dynamic, matrix:Matrix, colorTransform:ColorTransform, blendMode:String, clipRect:Rectangle, smoothing:Bool):Void;
	
}