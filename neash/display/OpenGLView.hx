package neash.display;

import neash.Loader;
import neash.gl.GL;
import neash.geom.Matrix3D;

//import neash.gl.GLInstance;

class OpenGLView extends DirectRenderer
{
   public static inline var CONTEXT_LOST = "glcontextlost";
   public static inline var CONTEXT_RESTORED = "glcontextrestored";

   //var context:GLInstance;

   public function new()
   {
     super("OpenGLView");
   }
}

