package nme.gl;

@:nativeProperty
class GL3
{
   #if (gles3 && !flash)

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

