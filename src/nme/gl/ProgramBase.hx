package nme.gl;

import nme.geom.Matrix3D;
import nme.utils.*;
import nme.gl.GL;

class ProgramBase
{
   var primCount:Int;
   var primType:Int;

   public function new( inPrimType:Int, inPrimCount:Int)
   {
      primType = inPrimType;
      primCount = inPrimCount;
   }

   public function dispose() { }

   public function render(mvp:Float32Array) { }

   public function renderMtx(mvp:Matrix3D) render( Float32Array.fromMatrix(mvp) );

}



