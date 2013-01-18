package native.display3D.textures;
#if (cpp || neko)


import native.display.BitmapData;
import native.gl.GL;
import native.gl.GLTexture;
import native.utils.ByteArray;


class RectangleTexture extends TextureBase {


    public function new (glTexture:GLTexture) {

        super (glTexture);

    }

	
	
	public function uploadFromBitmapData(source:BitmapData):Void {
		
		// TODO
		
	}
	
	
	public function uploadFromByteArray(data:ByteArray, byteArrayOffset:Int):Void {
		
		// TODO
		
	}
	
	
}


#end