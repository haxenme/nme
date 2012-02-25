package nme.display;
#if (cpp || neko)


import nme.geom.ColorTransform;
import nme.geom.Matrix;
import nme.geom.Rectangle;


interface IBitmapDrawable
{	
	
	/**
	 * @private
	 */
	public function nmeDrawToSurface(inSurface:Dynamic, matrix:Matrix, colorTransform:ColorTransform, blendMode:String, clipRect:Rectangle, smoothing:Bool):Void;
	
}


#elseif js


import nme.display.BlendMode;
import nme.geom.ColorTransform;
import nme.geom.Matrix;
import nme.geom.Rectangle;

interface IBitmapDrawable {
	function drawToSurface(inSurface : Dynamic,
			matrix:Matrix,
			colorTransform:ColorTransform,
			blendMode:BlendMode,
			clipRect:Rectangle,
			smoothing:Bool):Void;

}


#else
typedef IBitmapDrawable = flash.display.IBitmapDrawable;
#end