package ;

import nme.display.Sprite;
import neash.display.OpenGLView;
import neash.gl.GL;
import neash.utils.Float32Array;
import neash.geom.Matrix3D;
import neash.geom.Vector3D;
import neash.geom.Rectangle;

class Main extends Sprite
{
   function createShader(source:String, type:Int)
   {
      var shader = GL.createShader(type);
      GL.shaderSource(shader, source);
      GL.compileShader(shader);
      var err = GL.getShaderInfoLog(shader);
      if (err!="")
         throw err;
      return shader;
   }

   function createProgram(inVertexSource:String, inFragmentSource:String)
   {
      var program = GL.createProgram();
      var vshader = createShader(inVertexSource, GL.VERTEX_SHADER);
      var fshader = createShader(inFragmentSource, GL.FRAGMENT_SHADER);
      GL.attachShader(program, vshader);
      GL.attachShader(program, fshader);
      GL.linkProgram(program);
      var result = GL.getProgramInfoLog(program);
      if (result!="")
         throw result;
      return program;
   }

   public function new()
   {
      super();

      var ogl = new neash.display.OpenGLView();

      var vertexSource = 'attribute vec2 pos;' +
        'uniform mat4 uProj;' +
        'uniform mat4 uMV;' +
        'void main() { gl_Position = uProj * uMV * vec4(pos, 0.0, 1.0); }';

      var fragmentSource = // - not on desktop ? 'precision mediump float;' +
        'void main() { gl_FragColor = vec4(0,0.8,0,1); }';

      var prog = createProgram(vertexSource,fragmentSource);

      var vertexPosAttrib = GL.getAttribLocation(prog, 'pos');
      var uProj = GL.getUniformLocation(prog, 'uProj');
      var uMV = GL.getUniformLocation(prog, 'uMV');

      var vertexPosBuffer = GL.createBuffer();

      var posX = 200.0;
      var posY = 120.0;
      var rot  = 0.0;

      GL.bindBuffer(GL.ARRAY_BUFFER, vertexPosBuffer);
      var vertices = [ -100,-100,   200,20,  20,200 ];

      GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(vertices), GL.STATIC_DRAW);

      addChild(ogl);
      ogl.render = function(rect:Rectangle)
      {
         // Use the display list rectangle..
         var w = rect.width;
         var h = rect.height;
         GL.viewport(Std.int(rect.x), Std.int(rect.y), Std.int(w), Std.int(h));

         // Only need the scissor if we want to limit the clear 
         GL.scissor(Std.int(rect.x), Std.int(rect.y), Std.int(w), Std.int(h));
         GL.enable(GL.SCISSOR_TEST);
         GL.clearColor(0.1,0.2,0.5,1);
         GL.clear(GL.COLOR_BUFFER_BIT);
         GL.disable(GL.SCISSOR_TEST);

         GL.useProgram(prog);

         // Reverse Y - so 0,0 is top left...
         GL.uniformMatrix3D(uProj, false, Matrix3D.createOrtho(0,w, h,0, 1000, -1000) );

         GL.uniformMatrix3D(uMV  , false, Matrix3D.create2D(posX, posY, 1, rot ) );

         GL.enableVertexAttribArray(vertexPosAttrib);

         GL.bindBuffer(GL.ARRAY_BUFFER, vertexPosBuffer);

         GL.vertexAttribPointer(vertexPosAttrib, 2, GL.FLOAT, false, 0, 0);

         GL.drawArrays(GL.TRIANGLES, 0, 3);

         GL.bindBuffer(GL.ARRAY_BUFFER, null);
         GL.useProgram(null);

         rot = rot + 1.0;
      }
      ogl.scrollRect = new nme.geom.Rectangle(0,0,400,300);
      ogl.x = 60;
      ogl.y = 70;
   }
}
