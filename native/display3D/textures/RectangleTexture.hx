package native.display3D.textures;


import native.display.BitmapData;
import native.utils.ByteArray;
import native.gl.GL;

class RectangleTexture extends TextureBase {


    public function new (glTexture:native.gl.Texture) {

        super (glTexture);

    }
	
	
	public function uploadFromBitmapData (source:BitmapData):Void {
		
		// TODO
		
	}
	
	
	public function uploadFromByteArray (data:ByteArray, byteArrayOffset:Int):Void {
		
		// TODO
		
	}
	
	
}