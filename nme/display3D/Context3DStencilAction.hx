package nme.display3D;
#if display


@:fakeEnum(String) extern enum Context3DStencilAction {
	DECREMENT_SATURATE;
	DECREMENT_WRAP;
	INCREMENT_SATURATE;
	INCREMENT_WRAP;
	INVERT;
	KEEP;
	SET;
	ZERO;
}


#elseif (cpp || neko)
typedef Context3DStencilAction = native.display3D.Context3DStencilAction;
#elseif !js
typedef Context3DStencilAction = flash.display3D.Context3DStencilAction;
#end