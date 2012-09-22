package ;

import nme.display.Sprite;
import nme.RGB;
import neash.display.OpenGLView;
import neash.display.BitmapData;
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
      if (GL.getShaderParameter(shader, GL.COMPILE_STATUS)==0)
      {
         var err = GL.getShaderInfoLog(shader);
         if (err!="")
            throw err;
      }
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
      if (GL.getProgramParameter(program, GL.LINK_STATUS)==0)
      {
         var result = GL.getProgramInfoLog(program);
         if (result!="")
            throw result;
      }

      return program;
   }

   public function new()
   {
      super();

      var bmp = new BitmapData(64,64,false,RGB.WHITE);
      var shape = new nme.display.Shape();
      var gfx = shape.graphics;
      gfx.beginFill(0xff0000);
      gfx.drawCircle(32,32,30);
      bmp.draw(shape);

      var ogl = new neash.display.OpenGLView();

      var vertexSource =
        "attribute vec2 aPos;" +
        "attribute vec4 aVertexColor;" +
        "attribute vec2 aTexCoord;" +
        "uniform mat4 uProj;" +
        "uniform mat4 uMV;" +
        "varying vec4 vColor;" +
        "varying vec2 vTexCoord;" +
        "void main() {" +
        " gl_Position = uProj * uMV * vec4(aPos, 0.0, 1.0);" +
        " vColor = aVertexColor;" +
        " vTexCoord = aTexCoord;" +
        "}";

      var fragmentSource = // - not on desktop ? 'precision mediump float;' +
        "varying vec4 vColor;" +
        "varying vec2 vTexCoord;" +
        "uniform sampler2D uSampler;" +
        "void main() {" +
        "gl_FragColor = vColor * texture2D(uSampler, vTexCoord);"+
        "}";

      var prog = createProgram(vertexSource,fragmentSource);

      var vertexPosAttrib = GL.getAttribLocation(prog, "aPos");
      GL.enableVertexAttribArray(vertexPosAttrib);

      var uProj = GL.getUniformLocation(prog, "uProj");
      var uMV = GL.getUniformLocation(prog, "uMV");
      var uSampler = GL.getUniformLocation(prog, "uSampler");
      var colourAttrib = GL.getAttribLocation(prog, "aVertexColor");
      GL.enableVertexAttribArray(colourAttrib);
      var texAttrib = GL.getAttribLocation(prog, "aTexCoord");
      GL.enableVertexAttribArray(texAttrib);


      var posX = 200.0;
      var posY = 120.0;
      var rot  = 0.0;

      var vertices = [
         -100.0,-100,
         200,20,
         20,200 ];
      var vertexPosBuffer = GL.createBuffer();
      GL.bindBuffer(GL.ARRAY_BUFFER, vertexPosBuffer);
      GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(vertices), GL.STATIC_DRAW);

      var colours = [
          1.0,  0.0,  0.0,  1.0,    // red
          0.0,  1.0,  0.0,  1.0,    // green
          0.0,  0.0,  1.0,  1.0     // blue
        ];
      var colourBuffer = GL.createBuffer();
      GL.bindBuffer(GL.ARRAY_BUFFER, colourBuffer);
      GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(colours), GL.STATIC_DRAW);

      var texture = [
          0.0,  0.0,
          4.0,  0.0,
          0.0,  4.0,
        ];
      var texBuffer = GL.createBuffer();
      GL.bindBuffer(GL.ARRAY_BUFFER, texBuffer);
      GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(texture), GL.STATIC_DRAW);



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

         // Setup position array
         GL.bindBuffer(GL.ARRAY_BUFFER, vertexPosBuffer);
         GL.vertexAttribPointer(vertexPosAttrib, 2, GL.FLOAT, false, 0, 0);

         // Setup colour array
         GL.bindBuffer(GL.ARRAY_BUFFER, colourBuffer);
         GL.vertexAttribPointer(colourAttrib, 4, GL.FLOAT, false, 0, 0);

         // Setup texure array
         GL.bindBuffer(GL.ARRAY_BUFFER, texBuffer);
         GL.vertexAttribPointer(texAttrib, 2, GL.FLOAT, false, 0, 0);

         // Setup texure
         GL.uniform1i(uSampler, 0);
         GL.activeTexture(GL.TEXTURE0);
         GL.bindBitmapDataTexture(bmp);

         // Draw!
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
