package native.display3D.textures;
#if (cpp || neko)


import nme.display.BitmapData;
import nme.gl.GL;
import nme.gl.GLTexture;
import nme.utils.ByteArray;


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