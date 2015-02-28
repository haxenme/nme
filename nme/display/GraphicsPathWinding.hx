package nme.display;
#if (cpp || neko)

@:nativeProperty
class GraphicsPathWinding 
{
   public static inline var EVEN_ODD:String = "evenOdd";
   public static inline var NON_ZERO:String = "nonZero";
}

#else
typedef GraphicsPathWinding = flash.display.GraphicsPathWinding;
#end
