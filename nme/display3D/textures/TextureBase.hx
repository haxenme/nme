package nme.display3D.textures;
#if (!flash)

import nme.geom.Rectangle;
import nme.utils.ByteArray;
import nme.display.BitmapData;
import nme.gl.GL;
import nme.gl.GLTexture;
import nme.events.EventDispatcher;

@:nativeProperty
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

#else
typedef TextureBase = flash.display3D.textures.TextureBase;
#end
