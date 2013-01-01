package nme.display3D;
#if display


@:fakeEnum(String) extern enum Context3DVertexBufferFormat {
	BYTES_4;
	FLOAT_1;
	FLOAT_2;
	FLOAT_3;
	FLOAT_4;
}


#elseif (cpp || neko)
typedef Context3DVertexBufferFormat = native.display3D.Context3DVertexBufferFormat;
#elseif !js
typedef Context3DVertexBufferFormat = flash.display3D.Context3DVertexBufferFormat;
#end