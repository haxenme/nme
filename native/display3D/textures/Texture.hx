package native.display3D.textures;


import native.display.BitmapData;
import native.gl.GL;
import native.geom.Rectangle;
import native.utils.ArrayBuffer;
import native.utils.ArrayBufferView;
import native.utils.ByteArray;


class Texture extends TextureBase {
	
	
	public var glTexture:native.gl.Texture;
	
	
	public function new (glTexture:native.gl.Texture) {
		
		super ();
		
		this.glTexture = glTexture;
		
	}
	
	
	public function uploadCompressedTextureFromByteArray (data:ByteArray, byteArrayOffset:Int, async:Bool = false):Void {
		
		// TODO
		
	}
	
	
	public function uploadFromBitmapData (bitmapData:BitmapData, miplevel:Int = 0):Void {
		
		GL.bindTexture (GL.TEXTURE_2D, glTexture);
		
		var p = bitmapData.getPixels (new Rectangle (0, 0, bitmapData.width, bitmapData.height));
		var num =  bitmapData.width * bitmapData.height;
		
		for (i in 0...num) {
			
			var alpha = p[i * 4];
			var red = p[i * 4 + 1];
			var green = p[i * 4 + 2];
			var blue = p[i * 4 + 3];
			
			p[i * 4] = red;
			p[i * 4 + 1] = green;
			p[i * 4 + 2] = blue;
			p[i * 4 + 3] = alpha;
			
		}
		
		GL.texImage2D (GL.TEXTURE_2D, 0, GL.RGBA, bitmapData.width, bitmapData.height, 0, GL.RGBA, GL.UNSIGNED_BYTE, new ArrayBufferView (p, 0));
		
	}
	
	
	public function uploadFromByteArray (data:ByteArray, byteArrayOffset:Int, miplevel:Int = 0):Void {
		
		// TODO
		
	}
	
	
}