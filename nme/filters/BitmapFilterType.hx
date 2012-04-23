package nme.filters;
#if code_completion


@:fakeEnum(String) extern enum BitmapFilterType {
	FULL;
	INNER;
	OUTER;
}


#elseif (cpp || neko)
typedef BitmapFilterType = neash.filters.BitmapFilterType;
#elseif js
typedef BitmapFilterType = jeash.filters.BitmapFilterType;
#else
typedef BitmapFilterType = flash.filters.BitmapFilterType;
#end