package nme.display3D;

#if flash
typedef IndexBuffer3D = flash.display3D.IndexBuffer3D;
#elseif cpp
typedef IndexBuffer3D = native.display3D.IndexBuffer3D;
#end
