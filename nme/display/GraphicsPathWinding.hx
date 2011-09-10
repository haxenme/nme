package nme.display;


#if flash
@:native ("flash.display.GraphicsPathWinding")
@:fakeEnum(String) extern enum GraphicsPathWinding {
	EVEN_ODD;
	NON_ZERO;
}
#else



class GraphicsPathWinding
{
   public static inline var EVEN_ODD = "evenOdd";
   public static inline var NON_ZERO = "nonZero";
}
#end