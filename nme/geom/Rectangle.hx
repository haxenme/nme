package nme.geom;

#if (cpp || neko)

typedef Rectangle = neash.geom.Rectangle;

#elseif js

typedef Rectangle = jeash.geom.Rectangle;

#else

typedef Rectangle = flash.geom.Rectangle;

#end