package nme.filters;
#if code_completion


extern class BitmapFilter {
	function new() : Void;
	function clone() : BitmapFilter;
}


#elseif (cpp || neko)
typedef BitmapFilter = neash.filters.BitmapFilter;
#elseif js
typedef BitmapFilter = jeash.filters.BitmapFilter;
#else
typedef BitmapFilter = flash.filters.BitmapFilter;
#end