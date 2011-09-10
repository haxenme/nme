#if flash


package nme.filters;


@:native ("flash.filters.BitmapFilterQuality")
extern class BitmapFilterQuality {
	static inline var HIGH : Int = 3;
	static inline var LOW : Int = 1;
	static inline var MEDIUM : Int = 2;
}



#else


package nme.filters;

class BitmapFilterQuality
{
   public static var HIGH = 3;
   public static var MEDIUM = 2;
   public static var LOW = 1;
}


#end