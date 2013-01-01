package nme.display3D;

#if flash
typedef Program3D = flash.display3D.Program3D;
#elseif cpp
typedef Program3D = native.display3D.Program3D;
#end