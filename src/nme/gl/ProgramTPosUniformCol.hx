package nme.gl;

import nme.geom.Matrix3D;
import nme.utils.*;
import nme.gl.GL;

// Used for drawing geometry using a view matrix and constant colour
class ProgramTPosUniformCol extends ProgramBase
{
   static var prog:GLProgram;
   static var posLocation:Dynamic;
   static var colourLocation:Dynamic;
   static var mvpLocation:Dynamic;

   var posBuffer:GLBuffer;

   public var colA:Float;
   public var colR:Float;
   public var colG:Float;
   public var colB:Float;

   public function new(inVertices:Float32Array, inColour:Int, inPrim:Int, inPrimCount:Int)
   {
      super(inPrim, inPrimCount);

      colA = ((inColour>>24) & 0xff)/255.0;
      colR = ((inColour>>16) & 0xff)/255.0;
      colG = ((inColour>>8) & 0xff)/255.0;
      colB = ((inColour) & 0xff)/255.0;

      primType = inPrim;
      primCount = inPrimCount;

      posBuffer = GL.createBuffer();
      GL.bindBuffer(GL.ARRAY_BUFFER, posBuffer);
      GL.bufferData(GL.ARRAY_BUFFER, inVertices, GL.STATIC_DRAW);
      GL.bindBuffer(GL.ARRAY_BUFFER, null);

      if (prog==null || !prog.valid)
      {
           var vertShader =
              "in vec3 pos;" +
              "uniform mat4 mvp;" +
              "void main() {" +
              " gl_Position = mvp * vec4(pos, 1.0);" +
              "}";

            var fragShader =
              #if !desktop 'precision mediump float;' + #end
              "uniform vec4 col = vec4(1.0, 0.0, 0.0, 1.0);" +
              "void main() {" +
              "gl_FragColor = col;"+
              "}";

         prog = Utils.createProgram(vertShader,fragShader);
         posLocation = GL.getAttribLocation(prog, "pos");
         colourLocation = GL.getUniformLocation(prog, "col");
         mvpLocation = GL.getUniformLocation(prog, "mvp");
      }
   }

   override public function render(mvp:Float32Array)
   {
      GL.useProgram(prog);

      GL.bindBuffer(GL.ARRAY_BUFFER, posBuffer);
      GL.vertexAttribPointer(posLocation, 3, GL.FLOAT, false, 0, 0);
      GL.enableVertexAttribArray(posLocation);

      GL.uniformMatrix4fv(mvpLocation, false, mvp);

      GL.uniform4f(colourLocation, colR, colG, colB, colA);

      GL.drawArrays(primType, 0, primCount);

      GL.disableVertexAttribArray(posLocation);
   }


   override public function dispose()
   {
      GL.deleteBuffer(posBuffer);
   }


   public static function createLines(vertices:Float32Array, colour)
   {
      var count = vertices.length;
      if (count<1 || (count%6>0))
         throw "vertices length should be a multiple of 6";
      count = Std.int(count/3);
      return new ProgramTPosUniformCol(vertices, colour, GL.LINES, count);
   }

   public static function createTriangles(vertices:Float32Array, colour:Int)
   {
      var count = vertices.length;
      if (count<1 || (count%9>0))
         throw "vertices length should be a multiple of 9";
      count = Std.int(count/3);
      return new ProgramTPosUniformCol(vertices, colour, GL.TRIANGLES, count);
   }

}

