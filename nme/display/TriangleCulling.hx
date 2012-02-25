package nme.display;
#if (cpp || neko)


enum TriangleCulling
{
   NEGATIVE;
   NONE;
   POSITIVE;
}


#else
typedef TriangleCulling = flash.display.TriangleCulling;
#end