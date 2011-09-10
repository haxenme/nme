#if flash


package nme.filters;


@:native ("flash.filters.BitmapFilterType")
@:fakeEnum(String) extern enum BitmapFilterType {
	FULL;
	INNER;
	OUTER;
}



#else


package nme.filters;

class BitmapFilterType
{
   public static var FULL = "full";
   public static var INNER = "inner";
   public static var OUTER = "outer";
}


#end