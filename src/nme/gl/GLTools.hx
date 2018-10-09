package nme.gl;

class GLTools
{
   public static function bind2D(texture:GLTexture)
   {
      GL.bindTexture( GL.TEXTURE_2D, texture );
   }
}
