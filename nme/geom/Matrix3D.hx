package nme.geom;

#if (cpp || neko)

typedef Matrix3D = neash.geom.Matrix3D;

#elseif js

typedef Matrix3D = jeash.geom.Matrix3D;

#else

typedef Matrix3D = flash.geom.Matrix3D;

#end