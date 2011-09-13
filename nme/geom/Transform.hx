package nme.geom;
#if cpp || neko


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


#else
typedef Transform = flash.geom.Transform;
#end