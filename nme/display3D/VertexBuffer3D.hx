package nme.display3D;
#if display


extern class VertexBuffer3D {
	function dispose() : Void;
	function uploadFromByteArray(data : nme.utils.ByteArray, byteArrayOffset : Int, startVertex : Int, numVertices : Int) : Void;
	function uploadFromVector(data : nme.Vector<Float>, startVertex : Int, numVertices : Int) : Void;
}


#elseif (cpp || neko)
typedef VertexBuffer3D = native.display3D.VertexBuffer3D;
#elseif !js
typedef VertexBuffer3D = flash.display3D.VertexBuffer3D;
#end