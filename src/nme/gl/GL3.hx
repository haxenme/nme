package nme.gl;

import nme.display.BitmapData;
import nme.utils.ArrayBuffer;
import nme.utils.ByteArray;
import nme.utils.IMemoryRange;
import nme.utils.ArrayBufferView;
import nme.geom.Matrix3D;
import nme.Lib;
import nme.Loader;

#if (neko||cpp)
import nme.utils.Float32Array;
import nme.utils.Int32Array;
#end


@:nativeProperty
class GL3
{

   #if (neko||cpp)

   public static inline function bindVertexArray(vertexarray:GLVertexArray):Void
   {
      nme_gl_bind_vertexarray(vertexarray);
   }

   public static inline function createVertexArray():GLVertexArray
   {
      return new GLVertexArray(GL.version, nme_gl_create_vertexarray());
   }


   // Native Methods
   private static var nme_gl_create_vertexarray = GL.load("nme_gl_create_vertexarray", 0);
   private static var nme_gl_bind_vertexarray = GL.load("nme_gl_bind_vertexarray", 1);

   #end
}

