package nme.display3D;
#if display


@:fakeEnum(String) extern enum Context3DCompareMode {
	ALWAYS;
	EQUAL;
	GREATER;
	GREATER_EQUAL;
	LESS;
	LESS_EQUAL;
	NEVER;
	NOT_EQUAL;
}


#elseif (cpp || neko)
typedef Context3DCompareMode = native.display3D.Context3DCompareMode;
#elseif !js
typedef Context3DCompareMode = flash.display3D.Context3DCompareMode;
#end