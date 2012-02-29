package nme.display;

#if (cpp || neko)

typedef TriangleCulling = neash.display.TriangleCulling;

#elseif js

typedef TriangleCulling = jeash.display.TriangleCulling;

#else

typedef TriangleCulling = flash.display.TriangleCulling;

#end