package nme.display3D;
#if display


@:fakeEnum(String) extern enum Context3DTriangleFace {
	BACK;
	FRONT;
	FRONT_AND_BACK;
	NONE;
}


#elseif (cpp || neko)
typedef Context3DTriangleFace = native.display3D.Context3DTriangleFace;
#elseif !js
typedef Context3DTriangleFace = flash.display3D.Context3DTriangleFace;
#end