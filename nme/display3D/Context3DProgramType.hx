package nme.display3D;

#if flash
typedef Context3DProgramType = flash.display3D.Context3DProgramType;
#elseif cpp
typedef Context3DProgramType = native.display3D.Context3DProgramType;
#end