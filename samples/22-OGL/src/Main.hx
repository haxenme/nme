package ;

import nme.display.Sprite;
import nme.RGB;
import nme.display.OpenGLView;
import nme.display.BitmapData;
import nme.gl.GL;
import nme.utils.Float32Array;
import nme.utils.ArrayBuffer;
import nme.utils.ArrayBufferView;
import nme.geom.Matrix3D;
import nme.geom.Vector3D;
import nme.geom.Rectangle;

class Utils
{
   public static function createShader(source:String, type:Int)
   {
      var shader = GL.createShader(type);
      GL.shaderSource(shader, source);
      GL.compileShader(shader);
      if (GL.getShaderParameter(shader, GL.COMPILE_STATUS)==0)
      {
         trace("--- ERR ---\n" + source);
         var err = GL.getShaderInfoLog(shader);
         if (err!="")
            throw err;
      }
      return shader;
   }

   public static function createProgram(inVertexSource:String, inFragmentSource:String)
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
}

class ProgramPosTex
{
   var prog:Program;

   var posLocation:Dynamic;
   var texLocation:Dynamic;
   var primCount:Int;
   var type:Int;
   public var posDims:Int;
   public var texDims:Int;
   var posBuffer:Buffer;
   var texBuffer:Buffer;
   var samplerLocation:Dynamic;
   public var texture(default,null):Texture;

   public function new(vertShader:String, posName:String, texName,
                       fragShader:String, samplerName:String )
   {
      prog = Utils.createProgram(vertShader,fragShader);
      posLocation = GL.getAttribLocation(prog, posName);
      texLocation = GL.getAttribLocation(prog, texName);
      samplerLocation = GL.getUniformLocation(prog, samplerName);
      posDims = 2;
      texDims = 2;
      createTexture();
      fillTexture();
   }



   public function setPosTex( pos:Array<Float>, texCoords:Array<Float>, inPrims:Int, inType:Int)
   {
      primCount = inPrims;
      type = inType;

      if (posBuffer==null)
         posBuffer = GL.createBuffer();
      GL.bindBuffer(GL.ARRAY_BUFFER, posBuffer);
      GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(pos), GL.STATIC_DRAW);
      if (texBuffer==null)
         texBuffer = GL.createBuffer();
      GL.bindBuffer(GL.ARRAY_BUFFER, texBuffer);
      GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(texCoords), GL.STATIC_DRAW);
   }

   public function createTexture()
   {
      texture = GL.createTexture();
      GL.bindTexture(GL.TEXTURE_2D, texture);

      GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE );
      GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE );
      GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
      GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
   }

   public function fillTexture()
   {
      var pixels = new ArrayBuffer(256*256*4);
      for(i in 0...256*256*4)
         pixels[i] = Std.random(256);
      GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, 256, 256, 0, GL.RGBA, GL.UNSIGNED_BYTE, new ArrayBufferView(pixels));
   }

   public function bindTexture()
   {
      GL.bindTexture(GL.TEXTURE_2D, texture);
   }

   public function render()
   {
      GL.useProgram(prog);

      GL.bindBuffer(GL.ARRAY_BUFFER, posBuffer);
      GL.vertexAttribPointer(posLocation, posDims, GL.FLOAT, false, 0, 0);
      GL.bindBuffer(GL.ARRAY_BUFFER, texBuffer);
      GL.vertexAttribPointer(texLocation, texDims, GL.FLOAT, false, 0, 0);

      GL.activeTexture(GL.TEXTURE0);
      bindTexture();
      GL.uniform1i(samplerLocation, 0);

      GL.enableVertexAttribArray(posLocation);
      GL.enableVertexAttribArray(texLocation);
      GL.drawArrays(type, 0, primCount);
      GL.disableVertexAttribArray(texLocation);
      GL.disableVertexAttribArray(posLocation);
   }
}

class TextureRect extends ProgramPosTex
{

   public function new()
   {
      var vertShader =
        "attribute vec2 aPos;" +
        "attribute vec2 aTexCoord;" +
        "varying vec2 vTexCoord;" +
        "void main() {" +
        " gl_Position = vec4(aPos, 0.0, 1.0);" +
        " vTexCoord = aTexCoord;" +
        "}";

      var texShader = // - not on desktop ? 'precision mediump float;' +
        "varying vec2 vTexCoord;" +
        "uniform sampler2D uSampler;" +
        "void main() {" +
        "gl_FragColor = texture2D(uSampler, vTexCoord);"+
        "}";

      super(vertShader, "aPos", "aTexCoord", texShader, "uSampler" );

      var pos = [ -1,-1,  -1,1.0,  1.0,1.0,  1.0,-1.0 ];
      var tex = [ 0.0,0.0,  0.0,1.0,  1.0,1.0,  1.0,0.0 ];

      setPosTex(pos,tex,4,GL.TRIANGLE_FAN);
   }

   override public function fillTexture()
   {
      var pixels = new ArrayBuffer(256*256*4);
      for(i in 0...256*256*4)
         pixels[i] = Std.random(256);
      GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, 256, 256, 0, GL.RGBA, GL.UNSIGNED_BYTE, new ArrayBufferView(pixels));
   }
}

class ProgramPosTexExtra extends ProgramPosTex
{
   var extraLocation:Dynamic;
   var extraBuffer:Dynamic;
   public var extraDims:Int;

   public function new(vertShader:String, posName:String, texName, extraName:String,
                       fragShader:String, samplerName:String )
   {
      super(vertShader,posName, texName,fragShader,samplerName);
      extraLocation = GL.getAttribLocation(prog, extraName);
      extraDims = 4;
   }

   public function setExtra( extra:Array<Float>, dim:Int )
   {
      extraDims = dim;
      if (extraBuffer==null)
         extraBuffer = GL.createBuffer();
      GL.bindBuffer(GL.ARRAY_BUFFER, extraBuffer);
      GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(extra), GL.STATIC_DRAW);
   }


   override public function render()
   {
      GL.useProgram(prog);

      GL.bindBuffer(GL.ARRAY_BUFFER, posBuffer);
      GL.vertexAttribPointer(posLocation, posDims, GL.FLOAT, false, 0, 0);
      GL.bindBuffer(GL.ARRAY_BUFFER, texBuffer);
      GL.vertexAttribPointer(texLocation, texDims, GL.FLOAT, false, 0, 0);
      GL.bindBuffer(GL.ARRAY_BUFFER, extraBuffer);
      GL.vertexAttribPointer(extraLocation, extraDims, GL.FLOAT, false, 0, 0);

      GL.activeTexture(GL.TEXTURE0);
      bindTexture();
      GL.uniform1i(samplerLocation, 0);

      GL.enableVertexAttribArray(posLocation);
      GL.enableVertexAttribArray(texLocation);
      GL.enableVertexAttribArray(extraLocation);
      GL.drawArrays(type, 0, primCount);
      GL.disableVertexAttribArray(texLocation);
      GL.disableVertexAttribArray(posLocation);
      GL.disableVertexAttribArray(extraLocation);
   }

}


class ColourBlend extends ProgramPosTexExtra
{
   var bmp:BitmapData;
   var uProj:Dynamic;
   var uMV:Dynamic;

   public function new()
   {
      var vertShader =
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

      var fragShader = // - not on desktop ? 'precision mediump float;' +
        "varying vec4 vColor;" +
        "varying vec2 vTexCoord;" +
        "uniform sampler2D uSampler;" +
        "void main() {" +
        "gl_FragColor = vColor * texture2D(uSampler, vTexCoord);"+
        "}";

      super(vertShader,"aPos","aTexCoord","aVertexColor", fragShader,"uSampler");

      uProj = GL.getUniformLocation(prog, "uProj");
      uMV = GL.getUniformLocation(prog, "uMV");
   }

   public function setTransform(inProj:Matrix3D, inMv:Matrix3D)
   {
      GL.useProgram(prog);
      GL.uniformMatrix3D(uProj, false, inProj );
      GL.uniformMatrix3D(uMV  , false, inMv );
   }

   override public function createTexture()
   {
      bmp = new BitmapData(64,64,false,RGB.WHITE);
   }
   override public function fillTexture()
   {
      var shape = new nme.display.Shape();
      var gfx = shape.graphics;
      gfx.beginFill(0xff0000);
      gfx.drawCircle(32,32,30);
      bmp.draw(shape);
   }
   override public function bindTexture() { GL.bindBitmapDataTexture(bmp); }

}


class Main extends Sprite
{
   public function new()
   {
      super();

      //trace(GL.getSupportedExtensions());

      var ogl = new native.display.OpenGLView();
      ogl.scrollRect = new nme.geom.Rectangle(0,0,400,300);
      ogl.x = 60;
      ogl.y = 70;


      var colouredTriangle = new ColourBlend();

      var vertices = [
         -100.0,-100,
         200,20,
         20,200 ];
      var texture = [
          0.0,  0.0,
          4.0,  0.0,
          0.0,  4.0,
        ];
      colouredTriangle.setPosTex(vertices, texture, 3, GL.TRIANGLES);

      var colours = [
          1.0,  0.0,  0.0,  1.0,    // red
          0.0,  1.0,  0.0,  1.0,    // green
          0.0,  0.0,  1.0,  1.0     // blue
        ];
      colouredTriangle.setExtra(colours,4);

      // create frame buffer...
      var frameBuffer = GL.createFramebuffer();
      GL.bindFramebuffer(GL.FRAMEBUFFER,frameBuffer);

      // create empty texture
      var tex = GL.createTexture();
      GL.bindTexture(GL.TEXTURE_2D, tex);
      GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
      GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR_MIPMAP_NEAREST);
      GL.generateMipmap(GL.TEXTURE_2D);
      GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, 512, 512, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);

      var renderbuffer = GL.createRenderbuffer();
      GL.bindRenderbuffer(GL.RENDERBUFFER, renderbuffer);
      GL.renderbufferStorage(GL.RENDERBUFFER, GL.DEPTH_COMPONENT16, 512, 512);

      GL.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, tex, 0);
      GL.framebufferRenderbuffer(GL.FRAMEBUFFER, GL.DEPTH_ATTACHMENT, GL.RENDERBUFFER, renderbuffer);

      GL.bindTexture(GL.TEXTURE_2D, null);
      GL.bindRenderbuffer(GL.RENDERBUFFER, null);
      GL.bindFramebuffer(GL.FRAMEBUFFER, null);

      //gl.bindFramebuffer(gl.FRAMEBUFFER, frameBuffer);
      //draw ...
      //gl.bindFramebuffer(gl.FRAMEBUFFER, null);


      var posX = 200.0;
      var posY = 120.0;
      var rot  = 0.0;

      var quad = new TextureRect();
 
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

         // Rener old buffer...
         quad.render();

         // Reverse Y - so 0,0 is top left...
         colouredTriangle.setTransform(Matrix3D.createOrtho(0,w, h,0, 1000, -1000),
                                       Matrix3D.create2D(posX, posY, 1, rot ) );

         colouredTriangle.render();


         // Copy screen rect into different sized texture to create stretch/swirl effect....
         quad.bindTexture();
         GL.copyTexImage2D(GL.TEXTURE_2D, 0, GL.RGB,
             Std.int(rect.x), Std.int(rect.y), Std.int(rect.width-1), Std.int(rect.height-1), 0);

         GL.useProgram(null);
         rot = rot + 1.0;
      }

   }
}
