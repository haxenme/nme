package nme.filters;
#if display


@:final extern class ColorMatrixFilter extends BitmapFilter {

	function new(matrix : Array<Float>) : Void;
	
}


#elseif (cpp || neko)
typedef ColorMatrixFilter = native.filters.ColorMatrixFilter;
#elseif js
typedef ColorMatrixFilter = browser.filters.ColorMatrixFilter;
#else
typedef ColorMatrixFilter = flash.filters.ColorMatrixFilter;
#end
