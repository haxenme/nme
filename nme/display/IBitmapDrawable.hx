package nme.display;
#if (cpp || neko)


import nme.geom.ColorTransform;
import nme.geom.Matrix;
import nme.geom.Rectangle;


interface IBitmapDrawable {
	
	
	public function nmeDrawToSurface (inSurface:Dynamic, matrix:Matrix, colorTransform:ColorTransform, blendMode:String, clipRect:Rectangle, smoothing:Bool):Void;
	

}


#else
typedef IBitmapDrawable = flash.display.IBitmapDrawable;
#end