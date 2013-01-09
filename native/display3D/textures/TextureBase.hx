package native.display3D.textures;


import nme.geom.Rectangle;
import nme.utils.ByteArray;
import browser.display.Bitmap;
import nme.display.BitmapData;
import native.gl.GL;
import native.events.EventDispatcher;


class TextureBase extends EventDispatcher {

    public var glTexture:native.gl.Texture;
	
	public function new (glTexture : native.gl.Texture) {
		
		super ();

        this.glTexture = glTexture;

    }
	
	
	public function dispose ():Void {

        GL.deleteTexture(glTexture);

	}
	
	
}