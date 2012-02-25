package nme.display;
#if (cpp || neko || js)


enum TriangleCulling
{
   NEGATIVE;
   NONE;
   POSITIVE;
}


#else
typedef TriangleCulling = flash.display.TriangleCulling;
#end