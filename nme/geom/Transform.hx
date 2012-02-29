package nme.geom;

#if (cpp || neko)

typedef Transform = neash.geom.Transform;

#elseif js

typedef Transform = jeash.geom.Transform;

#else

typedef Transform = flash.geom.Transform;

#end