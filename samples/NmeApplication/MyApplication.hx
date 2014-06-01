import nme.app.NmeApplication;
import nme.app.Window;

import nme.gl.GL;
import nme.gl.GLProgram;
import nme.gl.Buffer;
import nme.gl.Utils;

class MyApplication extends NmeApplication
{
   static var vertSource =
        "attribute vec2 aPos;" +
        "attribute vec3 aColour;" +
        "varying vec3 vColour;" +
        "void main() {" +
        " gl_Position = vec4(aPos, 0.0, 1.0);" +
        " vColour = aColour;" +
        "}";

   static var fragSource =
        "varying vec3 vColour;" +
        "void main() {" +
        "gl_FragColor = vec4(vColour.r,vColour.g,vColour.b,1);"+
        "}";

   var valid:Bool;
   var program:GLProgram;
   var posBuffer:Buffer;
   var colBuffer:Buffer;


   public function new(window:Window)
   {
      super(window);
      valid = false;
   }

   override public function onRender(_):Void
   {
      if (!valid)
      {
         program = Utils.createProgram(vertSource, fragSource);
         posBuffer = Buffer.fromArray(program,"aPos",2,[ -1,-1,  -1,1.0,  1.0,1.0,  1.0,-1.0 ] );
         colBuffer = Buffer.fromArray(program,"aColour",3,[ 0.0,0.0,0.0,  0.0,0.0,1.0,  1.0,0.0,1.0,  0.0,1.0,0.0 ]);
      }

      GL.useProgram(program);
      posBuffer.bind();
      colBuffer.bind();

      GL.drawArrays(GL.TRIANGLE_FAN, 0, 4);

      posBuffer.unbind();
      colBuffer.unbind();
   }

   override public function onContextLost():Void
   {
      valid = false;
   }

}
