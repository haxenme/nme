package nme.gl;
import nme.display.BitmapData;
import nme.utils.*;

class ProgramPosTex
{
   var prog:GLProgram;

   var posLocation:Dynamic;
   var mvpLocation:Dynamic;
   var texLocation:Dynamic;
   var primCount:Int;
   var type:Int;
   public var posDims:Int;
   public var texDims:Int;
   var posBuffer:GLBuffer;
   var texBuffer:GLBuffer;
   var samplerLocation:Dynamic;
   public var texture(default,null):GLTexture;
   var bitmap:BitmapData;


   static var defaultVertShader =
       "attribute vec3 aPos;" +
       "attribute vec2 aTexCoord;" +
       "uniform mat4 mvp;" +
       "varying vec2 vTexCoord;" +
       "void main() {" +
       "  vTexCoord = aTexCoord;" +
       "  vec4 p4 = vec4(aPos, 1.0);" +
       "  gl_Position = mvp * p4;" +
       "}";

   static var defaultTexShader =
      #if !desktop
      'precision mediump float;' +
      #end
        "varying vec2 vTexCoord;" +
        "uniform sampler2D uSampler;" +
        "void main() {" +
        "   gl_FragColor = texture2D(uSampler, vTexCoord);"+
        "}";


   public function new(vertShader:String, posName:String, texName,
                       fragShader:String, samplerName:String,
                       inPosDims=2, ?inBitmap:BitmapData)
   {
      prog = Utils.createProgram(vertShader,fragShader);
      posLocation = GL.getAttribLocation(prog, posName);
      texLocation = GL.getAttribLocation(prog, texName);
      samplerLocation = GL.getUniformLocation(prog, samplerName);
      if (inPosDims>2)
         mvpLocation = GL.getUniformLocation(prog, "mvp");
      posDims = inPosDims;
      texDims = 2;
      bitmap = inBitmap;
      trace("-------------------- mvpLocation : " + mvpLocation);
      if (bitmap==null)
      {
         createTexture();
         fillTexture();
      }
   }

   public static function create(?inBitmap:BitmapData)
   {
      return new ProgramPosTex(defaultVertShader, "aPos", "aTexCoord",
                 defaultTexShader, "uSampler", 3, inBitmap);
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
      var pixels = new UInt8Array(new ArrayBuffer(256*256*4));
	  
      for(i in 0...256*256*4)
         pixels[i] = Std.random(256);
      GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, 256, 256, 0, GL.RGBA, GL.UNSIGNED_BYTE, pixels);
   }

   public function dispose()
   {
      GL.deleteBuffer(posBuffer);
      GL.deleteBuffer(texBuffer);
      if (texture!=null)
         GL.deleteTexture(texture);
      GL.deleteProgram(prog);
   }


   public function bindTexture()
   {
      if (bitmap!=null)
         GL.bindBitmapDataTexture(bitmap);
      else
         GL.bindTexture(GL.TEXTURE_2D, texture);
   }

   public function render(?mvp:Float32Array)
   {
      GL.useProgram(prog);

      GL.bindBuffer(GL.ARRAY_BUFFER, posBuffer);
      GL.vertexAttribPointer(posLocation, posDims, GL.FLOAT, false, 0, 0);
      GL.bindBuffer(GL.ARRAY_BUFFER, texBuffer);
      GL.vertexAttribPointer(texLocation, texDims, GL.FLOAT, false, 0, 0);

      GL.activeTexture(GL.TEXTURE0);
      bindTexture();
      GL.uniform1i(samplerLocation, 0);

      if (mvp!=null)
         GL.uniformMatrix4fv(mvpLocation, false, mvp);

      GL.enableVertexAttribArray(posLocation);
      GL.enableVertexAttribArray(texLocation);
      GL.drawArrays(type, 0, primCount);
      GL.disableVertexAttribArray(texLocation);
      GL.disableVertexAttribArray(posLocation);
   }
}

