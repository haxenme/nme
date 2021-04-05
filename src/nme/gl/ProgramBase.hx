package nme.gl;

import nme.geom.Matrix3D;
import nme.geom.Vector3D;
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

   public function renderClipped(mvp:Float32Array, plane:Vector3D) render(mvp);


   public static function lineCount(vertices:Float32Array, colours:Int32Array)
   {
      var count = vertices.length;
      if (count<1 || (count%6>0))
         throw "vertices length should be a multiple of 6";
      count = Std.int(count/3);
      if (colours.length!=count)
         throw "There should be one colour per vertex";
      return count;
   }

   public static function triangleCount(vertices:Float32Array, colours:Int32Array)
   {
      var count = vertices.length;
      if (count<1 || (count%9>0))
         throw "vertices length should be a multiple of 9";
      count = Std.int(count/3);
      if (colours.length!=count)
         throw "There should be one colour per vertex";
      return count;
   }


}



