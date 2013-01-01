package nme.display3D.textures;
#if display


@:final extern class RectangleTexture extends TextureBase {
	function new() : Void;
	function uploadFromBitmapData(source : nme.display.BitmapData) : Void;
	function uploadFromByteArray(data : nme.utils.ByteArray, byteArrayOffset : UInt) : Void;
}


#elseif (cpp || neko)
typedef RectangleTexture = native.display3D.textures.RectangleTexture;
#elseif !js
typedef RectangleTexture = flash.display3D.textures.RectangleTexture;
#end