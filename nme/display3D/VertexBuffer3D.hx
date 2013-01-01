package nme.display3D;

#if flash
typedef VertexBuffer3D = flash.display3D.VertexBuffer3D;
#elseif cpp
typedef VertexBuffer3D = native.display3D.VertexBuffer3D;
#end