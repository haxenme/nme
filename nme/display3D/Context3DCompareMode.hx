package nme.display3D;

#if flash
typedef Context3DCompareMode = flash.display3D.Context3DCompareMode;
#elseif cpp
typedef Context3DCompareMode = native.display3D.Context3DCompareMode;
#end
