package nme.filters;


#if flash
@:native ("flash.filters.BitmapFilterType")
@:fakeEnum(String) extern enum BitmapFilterType {
	FULL;
	INNER;
	OUTER;
}
#else



class BitmapFilterType
{
   public static var FULL = "full";
   public static var INNER = "inner";
   public static var OUTER = "outer";
}
#end