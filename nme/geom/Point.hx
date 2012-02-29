package nme.geom;

#if (cpp || neko)

typedef Point = neash.geom.Point;

#elseif js

typedef Point = jeash.geom.Point;

#else

typedef Point = flash.geom.Point;

#end