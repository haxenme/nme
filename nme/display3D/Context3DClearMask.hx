package nme.display3D;
#if display


extern class Context3DClearMask {
	static var ALL : Int;
	static var COLOR : Int;
	static var DEPTH : Int;
	static var STENCIL : Int;
}


#elseif (cpp || neko)
typedef Context3DClearMask = native.display3D.Context3DClearMask;
#elseif !js
typedef Context3DClearMask = flash.display3D.Context3DClearMask;
#end