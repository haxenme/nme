package nme.geom;

#if (cpp || neko)

typedef Vector3D = neash.geom.Vector3D;

#elseif js

typedef Vector3D = jeash.geom.Vector3D;

#else

typedef Vector3D = flash.geom.Vector3D;

#end