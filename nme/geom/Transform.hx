#if flash


package nme.geom;


@:native ("flash.geom.Transform")
extern class Transform {
	var colorTransform : ColorTransform;
	var concatenatedColorTransform(default,null) : ColorTransform;
	var concatenatedMatrix(default,null) : Matrix;
	var matrix : Matrix;
	@:require(flash10) var matrix3D : Matrix3D;
	@:require(flash10) var perspectiveProjection : PerspectiveProjection;
	var pixelBounds(default,null) : Rectangle;
	function new(displayObject : flash.display.DisplayObject) : Void;
	@:require(flash10) function getRelativeMatrix3D(relativeTo : flash.display.DisplayObject) : Matrix3D;
}


#else


package nme.geom;

import nme.display.DisplayObject;


class Transform
{
   public var colorTransform( nmeGetColorTransform, nmeSetColorTransform ) : ColorTransform;
   public var concatenatedColorTransform( nmeGetConcatenatedColorTransform, null ) : ColorTransform;
   public var matrix(nmeGetMatrix,nmeSetMatrix):Matrix;
   public var concatenatedMatrix(nmeGetConcatenatedMatrix,null):Matrix;
   public var pixelBounds(nmeGetPixelBounds,null) : Rectangle;

   var nmeObj:DisplayObject;


   public function new(inParent:DisplayObject)
   {
      nmeObj = inParent;
   }


   function nmeGetMatrix() : Matrix
   {
      return nmeObj.nmeGetMatrix();
   }
   function nmeGetConcatenatedMatrix() : Matrix
   {
      return nmeObj.nmeGetConcatenatedMatrix();
   }
   function nmeSetMatrix(inMatrix:Matrix) : Matrix
   {
      nmeObj.nmeSetMatrix(inMatrix);
      return inMatrix;
   }

   function nmeGetColorTransform() : ColorTransform
   { 
      return nmeObj.nmeGetColorTransform();
   }
   function nmeGetConcatenatedColorTransform() : ColorTransform
   { 
      return nmeObj.nmeGetConcatenatedColorTransform();
   }

   function nmeSetColorTransform( inTrans : ColorTransform ) : ColorTransform
   {
      nmeObj.nmeSetColorTransform(inTrans);
      return inTrans;
   }

   function nmeGetPixelBounds() : Rectangle
   { 
      return nmeObj.nmeGetPixelBounds();
   }


}


#end