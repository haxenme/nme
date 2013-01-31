package native.display3D.textures;
#if (cpp || neko)


import nme.geom.Rectangle;
using nme.display.BitmapData;
import nme.utils.ByteArray;
import nme.gl.GL;
import nme.gl.GLTexture;


class CubeTexture extends TextureBase {



    public function new (glTexture:GLTexture) {

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


#end