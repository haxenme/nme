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
	
	private var nmeObj:DisplayObject;
	
	
	public function new(inParent:DisplayObject)
	{
		nmeObj = inParent;
	}
	
	
	
	// Getters & Setters
	
	
	
	private function nmeGetColorTransform():ColorTransform { return nmeObj.nmeGetColorTransform(); }
	private function nmeSetColorTransform(inTrans:ColorTransform):ColorTransform { nmeObj.nmeSetColorTransform(inTrans); return inTrans; }
	private function nmeGetConcatenatedColorTransform():ColorTransform { return nmeObj.nmeGetConcatenatedColorTransform(); }
	private function nmeGetConcatenatedMatrix():Matrix { return nmeObj.nmeGetConcatenatedMatrix(); }
	private function nmeGetMatrix():Matrix { return nmeObj.nmeGetMatrix(); }
	private function nmeSetMatrix(inMatrix:Matrix):Matrix { nmeObj.nmeSetMatrix(inMatrix); return inMatrix; }
	private function nmeGetPixelBounds():Rectangle { return nmeObj.nmeGetPixelBounds(); }
	
}


#elseif js


import nme.display.DisplayObject;
import nme.geom.Matrix;


class Transform
{
   public var colorTransform( GetColorTransform, SetColorTransform ) : ColorTransform;
   public var matrix(jeashGetMatrix,jeashSetMatrix):Matrix;
   public var pixelBounds(GetPixelBounds,null):Rectangle;

   var mObj:DisplayObject;

   public function new(inParent:DisplayObject)
   {
      mObj = inParent;
   }

   public function jeashGetMatrix() : Matrix { return mObj.jeashGetMatrix(); }
   public function jeashSetMatrix(inMatrix:Matrix) : Matrix
       { return mObj.jeashSetMatrix(inMatrix); }

   function GetPixelBounds()
   {
   	return mObj.getBounds(nme.Lib.jeashGetStage());
   }

   public function GetColorTransform() { 
#if silverlight
     var gfx = mObj.GetGraphics();
     return gfx.mColorTransform;
#else
     return new ColorTransform();
#end
   }

   public function SetColorTransform( inColorTransform : ColorTransform ) : ColorTransform
   {
#if silverlight
     mObj.GetGraphics().mColorTransform = colorTransform;
#end
     return inColorTransform;
   }
}


#else
typedef Transform = flash.geom.Transform;
#end