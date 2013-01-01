package nme.display3D;
#if display


@:fakeEnum(String) extern enum Context3DRenderMode {
	AUTO;
	SOFTWARE;
}


#elseif (cpp || neko)
typedef Context3DRenderMode = native.display3D.Context3DRenderMode;
#elseif !js
typedef Context3DRenderMode = flash.display3D.Context3DRenderMode;
#end