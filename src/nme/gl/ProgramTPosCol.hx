package nme.gl;

import nme.geom.Matrix3D;
import nme.geom.Vector3D;
import nme.utils.*;
import nme.gl.GL;

// Used for drawing geometry using a view matrix and constant colour
class ProgramTPosCol extends ProgramBase
{
   static var progClipped:GLProgram;
   static var posLocationClip:Dynamic;
   static var colLocationClip:Dynamic;
   static var mvpLocationClip:Dynamic;

   static var progUnclipped:GLProgram;
   static var posLocationUnclip:Dynamic;
   static var colLocationUnclip:Dynamic;
   static var mvpLocationUnclip:Dynamic;

   static var clipLocation:Dynamic;
   var posLocation:Dynamic;
   var colLocation:Dynamic;
   var mvpLocation:Dynamic;

   var posBuffer:GLBuffer;
   var colBuffer:GLBuffer;
   var clipped:Bool;
   var prog:GLProgram;

   public function new(inVertices:Float32Array, inColours:Int32Array, inPrim:Int, inPrimCount:Int,inClipped=false)
   {
      super(inPrim, inPrimCount);

      clipped = inClipped;
      posBuffer = GL.createBuffer();
      GL.bindBuffer(GL.ARRAY_BUFFER, posBuffer);
      GL.bufferData(GL.ARRAY_BUFFER, inVertices, GL.STATIC_DRAW);

      colBuffer = GL.createBuffer();
      GL.bindBuffer(GL.ARRAY_BUFFER, colBuffer);
      GL.bufferData(GL.ARRAY_BUFFER, inColours, GL.STATIC_DRAW);

      GL.bindBuffer(GL.ARRAY_BUFFER, null);

      prog = clipped ? progClipped : progUnclipped;

      if (prog==null || !prog.valid)
      {
         var vertShader =
              "in vec3 pos;" +
              "in vec4 col;" + 
              "uniform mat4 mvp;" +
              (clipped ? "uniform vec4 clip;" : "") +
              "out vec4 pCol;" + 
              "void main() {" +
              " pCol = col;" +
              " vec4 p4 = vec4(pos, 1.0);" +
              " gl_Position = mvp * p4;";

         if (clipped)
             vertShader += " gl_ClipDistance[0] = dot(p4,clip);";

         vertShader +=
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

         if (clipped)
            clipLocation = GL.getUniformLocation(prog, "clip");

         if (clipped)
         {
            progClipped = prog;
            posLocationClip = posLocation;
            mvpLocationClip = mvpLocation;
            colLocationClip = colLocation;
         }
         else
         {
            progUnclipped = prog;
            posLocationUnclip = posLocation;
            mvpLocationUnclip = mvpLocation;
            colLocationUnclip = colLocation;
         }
      }
      else if (clipped)
      {
         posLocation = posLocationClip;
         mvpLocation = mvpLocationClip;
         colLocation = colLocationClip;
      }
      else
      {
         posLocation = posLocationUnclip;
         mvpLocation = mvpLocationUnclip;
         colLocation = colLocationUnclip;
      }
   }

   override public function dispose()
   {
      GL.deleteBuffer(posBuffer);
      GL.deleteBuffer(colBuffer);
   }


   override public function render(mvp:Float32Array) renderClipped(mvp,null);

   override public function renderClipped(mvp:Float32Array, plane:Vector3D)
   {
      GL.useProgram(prog);

      GL.bindBuffer(GL.ARRAY_BUFFER, posBuffer);
      GL.vertexAttribPointer(posLocation, 3, GL.FLOAT, false, 0, 0);
      GL.enableVertexAttribArray(posLocation);

      GL.bindBuffer(GL.ARRAY_BUFFER, colBuffer);
      GL.vertexAttribPointer(colLocation, 4, GL.UNSIGNED_BYTE, true, 0, 0);
      GL.enableVertexAttribArray(colLocation);

      GL.uniformMatrix4fv(mvpLocation, false, mvp);

      if (clipped && plane!=null)
      {
         GL.uniform4f(clipLocation, plane.x, plane.y, plane.z, plane.w);
         GL.enable(GL.CLIP_DISTANCE0);
      }

      GL.drawArrays(primType, 0, primCount);

      GL.disableVertexAttribArray(posLocation);
      GL.disableVertexAttribArray(colLocation);
      GL.bindBuffer(GL.ARRAY_BUFFER, null);

      if (clipped && plane!=null)
         GL.disable(GL.CLIP_DISTANCE0);
   }


   public static function createLines(vertices:Float32Array, colours:Int32Array,clipped=false)
   {
      var count = ProgramBase.lineCount(vertices,colours);
      return new ProgramTPosCol(vertices, colours, GL.LINES, count,clipped);
   }

   public static function createTriangles(vertices:Float32Array, colours:Int32Array,clipped=false)
   {
      var count = ProgramBase.triangleCount(vertices,colours);
      return new ProgramTPosCol(vertices, colours, GL.TRIANGLES, count,clipped);
   }

}


