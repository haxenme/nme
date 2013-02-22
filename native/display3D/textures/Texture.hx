package native.display3D.textures;
#if (cpp || neko)

using nme.display.BitmapData;

import nme.geom.Rectangle;
import nme.gl.GL;
import nme.gl.GLTexture;
import nme.utils.ArrayBuffer;
import nme.utils.ByteArray;
import nme.utils.UInt8Array;

class Texture extends TextureBase 
{
   public var width : Int;
    public var height : Int;

	public function new(glTexture:GLTexture, width : Int, height : Int) {

		super (glTexture);
		this.width = width;
		this.height = height;

        GL.bindTexture (GL.TEXTURE_2D, glTexture);
        GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, width, height, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);


	}


	public function uploadCompressedTextureFromByteArray(data:ByteArray, byteArrayOffset:Int, async:Bool = false):Void {

		// TODO

	}


	public function uploadFromBitmapData (bitmapData:BitmapData, miplevel:Int = 0):Void {

        var p = bitmapData.getRGBAPixels();
        uploadFromByteArray(p, 0, miplevel);

	}


	public function uploadFromByteArray(data:ByteArray, byteArrayOffset:Int, miplevel:Int = 0):Void {

        GL.bindTexture (GL.TEXTURE_2D, glTexture);
        GL.texSubImage2D(GL.TEXTURE_2D, miplevel, 0, 0, width, height, GL.RGBA, GL.UNSIGNED_BYTE, new UInt8Array(data));

	}
}

#end