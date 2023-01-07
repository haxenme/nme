package nme.gl;

class ProgrameRectTex extends ProgramPosTex
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

      var texShader = // - not on desktop ? 
	  #if !desktop
	  'precision mediump float;' +
	  #end
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
      var pixels = new UInt8Array(new ArrayBuffer(256*256*4));
      for(i in 0...256*256*4)
         pixels[i] = Std.random(256);
      GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, 256, 256, 0, GL.RGBA, GL.UNSIGNED_BYTE, pixels);
   }
}

