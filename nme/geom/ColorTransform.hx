package nme.geom;

#if (cpp || neko)

typedef ColorTransform = neash.geom.ColorTransform;

#elseif js

typedef ColorTransform = jeash.geom.ColorTransform;

#else

typedef ColorTransform = flash.geom.ColorTransform;

#end