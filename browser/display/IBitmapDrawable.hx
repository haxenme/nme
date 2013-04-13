package browser.display;
#if js


import browser.display.BlendMode;
import browser.geom.ColorTransform;
import browser.geom.Matrix;
import browser.geom.Rectangle;


interface IBitmapDrawable {
	
	function drawToSurface(inSurface:Dynamic, matrix:Matrix, colorTransform:ColorTransform, blendMode:BlendMode, clipRect:Rectangle, smoothing:Bool):Void;
	
}


#end