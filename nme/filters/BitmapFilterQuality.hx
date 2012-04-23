package nme.filters;
#if code_completion


extern class BitmapFilterQuality {
	static inline var HIGH : Int = 3;
	static inline var LOW : Int = 1;
	static inline var MEDIUM : Int = 2;
}


#elseif (cpp || neko)
typedef BitmapFilterQuality = neash.filters.BitmapFilterQuality;
#elseif js
typedef BitmapFilterQuality = jeash.filters.BitmapFilterQuality;
#else
typedef BitmapFilterQuality = flash.filters.BitmapFilterQuality;
#end