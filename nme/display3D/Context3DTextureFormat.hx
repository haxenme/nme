package nme.display3D;
#if display


@:fakeEnum(String) extern enum Context3DTextureFormat {
	BGRA;
	COMPRESSED;
}


#elseif (cpp || neko)
typedef Context3DTextureFormat = native.display3D.Context3DTextureFormat;
#elseif !js
typedef Context3DTextureFormat = flash.display3D.Context3DTextureFormat;
#end