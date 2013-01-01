package nme.display3D.textures;
#if display


@:final extern class Texture extends TextureBase {
	function uploadCompressedTextureFromByteArray(data : nme.utils.ByteArray, byteArrayOffset : UInt, async : Bool = false) : Void;
	function uploadFromBitmapData(source : nme.display.BitmapData, miplevel : UInt = 0) : Void;
	function uploadFromByteArray(data : nme.utils.ByteArray, byteArrayOffset : UInt, miplevel : UInt = 0) : Void;
}


#elseif (cpp || neko)
typedef Texture = native.display3D.textures.Texture;
#elseif !js
typedef Texture = flash.display3D.textures.Texture;
#end