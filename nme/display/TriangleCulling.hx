package nme.display;
#if (!flash)

// The order of this enum is important
enum TriangleCulling 
{
   POSITIVE;
   NONE;
   NEGATIVE;
}

#else
typedef TriangleCulling = flash.display.TriangleCulling;
#end
