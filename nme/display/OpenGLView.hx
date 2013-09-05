package nme.display;
#if (cpp || neko)

import nme.Loader;
import nme.gl.GL;
import nme.geom.Matrix3D;
//import nme.gl.GLInstance;
class OpenGLView extends DirectRenderer 
{
   public static inline var CONTEXT_LOST = "glcontextlost";
   public static inline var CONTEXT_RESTORED = "glcontextrestored";

   public static var isSupported(get_isSupported, null):Bool;

   //var context:GLInstance;
   public function new() 
   {
      super("OpenGLView");
   }

   // Getters & Setters
   private static inline function get_isSupported():Bool 
   {
      return true;
   }
}

#end