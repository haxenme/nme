package ;

import nme.display.Sprite;
import neash.display.OpenGLView;
import neash.gl.GL;
import neash.utils.Float32Array;

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
        'void main() { gl_Position = vec4(pos, 0, 1); }';
      var fragmentSource = // - not on desktop ? 'precision mediump float;' +
        'void main() { gl_FragColor = vec4(0,0.8,0,1); }';

      var prog = createProgram(vertexSource,fragmentSource);

      // todo - var vertexPosAttrib = GL.getAttribLocation(prog, 'pos');

      var vertexPosBuffer = GL.createBuffer();

      GL.bindBuffer(GL.ARRAY_BUFFER, vertexPosBuffer);
      var vertices = [-0.5, -0.5, 0.5, -0.5, 0, 0.5];

      GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(vertices), GL.STATIC_DRAW);

      addChild(ogl);
      ogl.render = function(i)
      {
         GL.clearColor(1,0.2,0.5,1);
         GL.clear(GL.COLOR_BUFFER_BIT);

         // todo - GL.useProgram(prog);

         // todo - GL.vertexAttribPointer(vertexPosAttrib, 2, GL.FLOAT, false, 0, 0);

         GL.bindBuffer(GL.ARRAY_BUFFER, vertexPosBuffer);

         // todo - GL.drawArrays(GL.TRIANGLES, 0, 3);

         GL.bindBuffer(GL.ARRAY_BUFFER, null);
      }
      ogl.scrollRect = new nme.geom.Rectangle(100,100,200,300);
      ogl.x = 60;
      ogl.y = 70;
   }
}
