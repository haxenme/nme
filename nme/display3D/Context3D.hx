package nme.display3D;

#if flash
	typedef Context3D =  flash.display3D.Context3D;
#elseif cpp
	typedef Context3D = native.display3D.Context3D;
#end