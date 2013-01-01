package nme.display3D;
#if display


@:fakeEnum(String) extern enum Context3DBlendFactor {
	DESTINATION_ALPHA;
	DESTINATION_COLOR;
	ONE;
	ONE_MINUS_DESTINATION_ALPHA;
	ONE_MINUS_DESTINATION_COLOR;
	ONE_MINUS_SOURCE_ALPHA;
	ONE_MINUS_SOURCE_COLOR;
	SOURCE_ALPHA;
	SOURCE_COLOR;
	ZERO;
}


#elseif (cpp || neko)
typedef Context3DBlendFactor = native.display3D.Context3DBlendFactor;
#elseif !js
typedef Context3DBlendFactor = flash.display3D.Context3DBlendFactor;
#end