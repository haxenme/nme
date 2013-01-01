package nme.display3D.textures;
#if display


@:final extern class CubeTexture extends TextureBase {
	function uploadCompressedTextureFromByteArray(data : nme.utils.ByteArray, byteArrayOffset : UInt, async : Bool = false) : Void;
	function uploadFromBitmapData(source : nme.display.BitmapData, side : UInt, miplevel : UInt = 0) : Void;
	function uploadFromByteArray(data : nme.utils.ByteArray, byteArrayOffset : UInt, side : UInt, miplevel : UInt = 0) : Void;
}


#elseif (cpp || neko)
typedef CubeTexture = native.display3D.textures.CubeTexture;
#elseif !js
typedef CubeTexture = flash.display3D.textures.CubeTexture;
#end