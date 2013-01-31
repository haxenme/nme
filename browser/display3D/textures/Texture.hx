package browser.display3D.textures;
#if js


using nme.display.BitmapData;

import nme.geom.Rectangle;
import nme.gl.GL;
import nme.gl.GLTexture;
import nme.utils.ArrayBuffer;
import nme.utils.Float32Array;
import nme.utils.ByteArray;


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
		
		GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, bitmapData.width, bitmapData.height, 0, GL.RGBA, GL.UNSIGNED_BYTE, new Float32Array(p));
		
	}
	
	
	public function uploadFromByteArray(data:ByteArray, byteArrayOffset:Int, miplevel:Int = 0):Void {
		
		// TODO
		
	}
	
	
}


#end