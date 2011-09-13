package nme.display;
#if cpp || neko


class GraphicsPathWinding
{
   public static inline var EVEN_ODD = "evenOdd";
   public static inline var NON_ZERO = "nonZero";
}


#else
typedef GraphicsPathWinding = flash.display.GraphicsPathWinding;
#end