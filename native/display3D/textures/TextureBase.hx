package native.display3D.textures;
#if (cpp || neko)

import nme.geom.Rectangle;
import nme.utils.ByteArray;
import nme.display.BitmapData;
import nme.gl.GL;
import nme.gl.GLTexture;
import nme.events.EventDispatcher;

class TextureBase extends EventDispatcher 
{
    public var glTexture:GLTexture;

   public function new(glTexture:GLTexture) 
   {
      super();

        this.glTexture = glTexture;
    }

   public function dispose():Void 
   {
        GL.deleteTexture(glTexture);
   }
}

#end