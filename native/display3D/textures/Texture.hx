package native.display3D.textures;
#if (cpp || neko)


using native.display.BitmapData;

import native.geom.Rectangle;
import native.gl.GL;
import native.gl.GLTexture;
import native.utils.ArrayBuffer;
import native.utils.ArrayBufferView;
import native.utils.ByteArray;


class Texture extends TextureBase {

	
	public function new(glTexture:GLTexture) {

		super (glTexture);

	}
	
	
	public function uploadCompressedTextureFromByteArray(data:ByteArray, byteArrayOffset:Int, async:Bool = false):Void {
		
		// TODO
		
	}
	

	public function uploadFromBitmapData (bitmapData:BitmapData, miplevel:Int = 0):Void {

        GL.bindTexture (GL.TEXTURE_2D, glTexture);

        var p = bitmapData.getRGBAPixels();
		
		GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, bitmapData.width, bitmapData.height, 0, GL.RGBA, GL.UNSIGNED_BYTE, new ArrayBufferView(p, 0));
		
	}
	
	
	public function uploadFromByteArray(data:ByteArray, byteArrayOffset:Int, miplevel:Int = 0):Void {
		
		// TODO
		
	}
	
	
}


#end