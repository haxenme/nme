package nme.display3D;
#if display


@:fakeEnum(String) extern enum Context3DProgramType {
	FRAGMENT;
	VERTEX;
}


#elseif (cpp || neko)
typedef Context3DProgramType = native.display3D.Context3DProgramType;
#elseif !js
typedef Context3DProgramType = flash.display3D.Context3DProgramType;
#end