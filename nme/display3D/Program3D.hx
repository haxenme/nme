package nme.display3D;
#if display


@:final extern class Program3D {
	function dispose() : Void;
	function upload(vertexProgram : nme.utils.ByteArray, fragmentProgram : nme.utils.ByteArray) : Void;
}


#elseif (cpp || neko)
typedef Program3D = native.display3D.Program3D;
#elseif !js
typedef Program3D = flash.display3D.Program3D;
#end