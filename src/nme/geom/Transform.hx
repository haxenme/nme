package nme.geom;
#if !flash

import nme.display.DisplayObject;

@:nativeProperty
class Transform 
{
   public var colorTransform(get, set):ColorTransform;
   public var concatenatedColorTransform(get, null):ColorTransform;
   public var concatenatedMatrix(get, null):Matrix;
   public var matrix(get, set):Matrix;
   public var pixelBounds(get, null):Rectangle;

   /** @private */ private var nmeObj:DisplayObject;
   public function new(inParent:DisplayObject) 
   {
      nmeObj = inParent;
   }

   // Getters & Setters
   private function get_colorTransform():ColorTransform { return nmeObj.nmeGetColorTransform(); }
   private function set_colorTransform(inTrans:ColorTransform):ColorTransform { nmeObj.nmeSetColorTransform(inTrans); return inTrans; }
   private function get_concatenatedColorTransform():ColorTransform { return nmeObj.nmeGetConcatenatedColorTransform(); }
   private function get_concatenatedMatrix():Matrix { return nmeObj.nmeGetConcatenatedMatrix(); }
   private function get_matrix():Matrix { return nmeObj.nmeGetMatrix(); }
   private function set_matrix(inMatrix:Matrix):Matrix { nmeObj.nmeSetMatrix(inMatrix); return inMatrix; }
   private function get_pixelBounds():Rectangle { return nmeObj.nmeGetPixelBounds(); }
}

#else
typedef Transform = flash.geom.Transform;
#end
