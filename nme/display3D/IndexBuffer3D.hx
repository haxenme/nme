package nme.display3D;
#if display


@:final extern class IndexBuffer3D {
	function dispose() : Void;
	function uploadFromByteArray(data : nme.utils.ByteArray, byteArrayOffset : Int, startOffset : Int, count : Int) : Void;
	function uploadFromVector(data : nme.Vector<UInt>, startOffset : Int, count : Int) : Void;
}


#elseif (cpp || neko)
typedef IndexBuffer3D = native.display3D.IndexBuffer3D;
#elseif !js
typedef IndexBuffer3D = flash.display3D.IndexBuffer3D;
#end