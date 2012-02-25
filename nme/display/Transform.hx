// why is this class here?

package nme.display;
#if js


import nme.display.DisplayObject;
import nme.geom.Matrix;


class Transform {
   public var matrix(jeashGetMatrix,jeashSetMatrix):Matrix;

   var mObj:DisplayObject;

   public function new(inParent:DisplayObject) {
      mObj = inParent;
   }

   public function jeashGetMatrix() : Matrix { return mObj.jeashGetMatrix(); }
   public function jeashSetMatrix(inMatrix:Matrix) : Matrix { return mObj.jeashSetMatrix(inMatrix); }

}


#end