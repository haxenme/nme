package nme.geom;

#if (cpp || neko)

typedef Matrix = neash.geom.Matrix;

#elseif js

typedef Matrix = jeash.geom.Matrix;

#else

typedef Matrix = flash.geom.Matrix;

#end