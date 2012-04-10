package nme.geom;
#if (cpp || neko)


import nme.display.DisplayObject;


class Transform
{
	
	public var colorTransform(nmeGetColorTransform, nmeSetColorTransform):ColorTransform;
	public var concatenatedColorTransform(nmeGetConcatenatedColorTransform, null):ColorTransform;
	public var concatenatedMatrix(nmeGetConcatenatedMatrix, null):Matrix;
	public var matrix(nmeGetMatrix, nmeSetMatrix):Matrix;
	public var pixelBounds(nmeGetPixelBounds, null):Rectangle;
	
	/** @private */ private var nmeObj:DisplayObject;
	
	
	public function new(inParent:DisplayObject)
	{
		nmeObj = inParent;
	}
	
	
	
	// Getters & Setters
	
	
	
	/** @private */ private function nmeGetColorTransform():ColorTransform { return nmeObj.nmeGetColorTransform(); }
	/** @private */ private function nmeSetColorTransform(inTrans:ColorTransform):ColorTransform { nmeObj.nmeSetColorTransform(inTrans); return inTrans; }
	/** @private */ private function nmeGetConcatenatedColorTransform():ColorTransform { return nmeObj.nmeGetConcatenatedColorTransform(); }
	/** @private */ private function nmeGetConcatenatedMatrix():Matrix { return nmeObj.nmeGetConcatenatedMatrix(); }
	/** @private */ private function nmeGetMatrix():Matrix { return nmeObj.nmeGetMatrix(); }
	/** @private */ private function nmeSetMatrix(inMatrix:Matrix):Matrix { nmeObj.nmeSetMatrix(inMatrix); return inMatrix; }
	/** @private */ private function nmeGetPixelBounds():Rectangle { return nmeObj.nmeGetPixelBounds(); }
	
}


#else
typedef Transform = flash.geom.Transform;
#end