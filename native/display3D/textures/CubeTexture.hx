package native.display3D.textures;


import nme.geom.Rectangle;
using native.display.BitmapData;
import native.utils.ByteArray;
import native.gl.GL;


class CubeTexture extends TextureBase {



    public function new (glTexture:native.gl.Texture) {

        super (glTexture);

    }

	
	public function uploadCompressedTextureFromByteArray(data:ByteArray, byteArrayOffset:Int, async:Bool = false):Void {
		
		// TODO
		
	}
	

	public function uploadFromBitmapData (source:BitmapData, side:Int, miplevel:Int = 0):Void {

        GL.bindTexture (GL.TEXTURE_CUBE_MAP, glTexture);

        var p = source.getRGBAPixels();

        // TODO
        //GL.texImage2D (GL.TEXTURE_CUBE_MAP, 0, GL.RGBA, source.width, source.height, 0, GL.RGBA, GL.UNSIGNED_BYTE, new ArrayBufferView (source, 0));
		
	}
	
	
	public function uploadFromByteArray(data:ByteArray, byteArrayOffset:Int, side:Int, miplevel:Int = 0):Void {
		
		// TODO
		
	}
	
	
}