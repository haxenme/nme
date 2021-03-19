package nme.gl;

import nme.geom.Matrix3D;
import nme.utils.*;
import nme.gl.GL;

// Used for drawing geometry using a view matrix and constant colour
class ProgramTPosCol extends ProgramBase
{
   static var prog:GLProgram;
   static var posLocation:Dynamic;
   static var colLocation:Dynamic;
   static var mvpLocation:Dynamic;

   var posBuffer:GLBuffer;
   var colBuffer:GLBuffer;

   public function new(inVertices:Float32Array, inColours:Int32Array, inPrim:Int, inPrimCount:Int)
   {
      super(inPrim, inPrimCount);

      posBuffer = GL.createBuffer();
      GL.bindBuffer(GL.ARRAY_BUFFER, posBuffer);
      GL.bufferData(GL.ARRAY_BUFFER, inVertices, GL.STATIC_DRAW);

      colBuffer = GL.createBuffer();
      GL.bindBuffer(GL.ARRAY_BUFFER, colBuffer);
      GL.bufferData(GL.ARRAY_BUFFER, inColours, GL.STATIC_DRAW);

      GL.bindBuffer(GL.ARRAY_BUFFER, null);

      if (prog==null || !prog.valid)
      {
           var vertShader =
              "in vec3 pos;" +
              "in vec4 col;" + 
              "out vec4 pCol;" + 
              "uniform mat4 mvp;" +
              "void main() {" +
              " pCol = col;" +
              " gl_Position = mvp * vec4(pos, 1.0);" +
              "}";

            var fragShader =
              #if !desktop 'precision mediump float;' + #end
              "in vec4 pCol;" + 
              "void main() {" +
              "gl_FragColor = pCol;"+
              "}";

         prog = Utils.createProgram(vertShader,fragShader);
         posLocation = GL.getAttribLocation(prog, "pos");
         colLocation = GL.getAttribLocation(prog, "col");
         mvpLocation = GL.getUniformLocation(prog, "mvp");
      }
   }

   override public function dispose()
   {
      GL.deleteBuffer(posBuffer);
      GL.deleteBuffer(colBuffer);
   }


   override public function render(mvp:Float32Array)
   {
      GL.useProgram(prog);

      GL.bindBuffer(GL.ARRAY_BUFFER, posBuffer);
      GL.vertexAttribPointer(posLocation, 3, GL.FLOAT, false, 0, 0);
      GL.enableVertexAttribArray(posLocation);

      GL.bindBuffer(GL.ARRAY_BUFFER, colBuffer);
      GL.vertexAttribPointer(colLocation, 4, GL.UNSIGNED_BYTE, true, 0, 0);
      GL.enableVertexAttribArray(colLocation);

      GL.uniformMatrix4fv(mvpLocation, false, mvp);

      GL.drawArrays(primType, 0, primCount);

      GL.disableVertexAttribArray(posLocation);
      GL.disableVertexAttribArray(colLocation);
      GL.bindBuffer(GL.ARRAY_BUFFER, null);
   }


   public static function createLines(vertices:Float32Array, colours:Int32Array)
   {
      var count = vertices.length;
      if (count<1 || (count%6>0))
         throw "vertices length should be a multiple of 6";
      count = Std.int(count/3);
      if (colours.length!=count)
         throw "There should be one colour per vertex";
      return new ProgramTPosCol(vertices, colours, GL.LINES, count);
   }

   public static function createTriangles(vertices:Float32Array, colours:Int32Array)
   {
      var count = vertices.length;
      if (count<1 || (count%9>0))
         throw "vertices length should be a multiple of 9";
      count = Std.int(count/3);
      if (colours.length!=count)
         throw "There should be one colour per vertex";
      return new ProgramTPosCol(vertices, colours, GL.TRIANGLES, count);
   }

}


