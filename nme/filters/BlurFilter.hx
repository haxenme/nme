package nme.filters;
#if code_completion


@:final extern class BlurFilter extends BitmapFilter {
	var blurX : Float;
	var blurY : Float;
	var quality : Int;
	function new(blurX : Float = 4, blurY : Float = 4, quality : Int = 1) : Void;
}


#elseif (cpp || neko)
typedef BlurFilter = neash.filters.BlurFilter;
#elseif js
typedef BlurFilter = jeash.filters.BlurFilter;
#else
typedef BlurFilter = flash.filters.BlurFilter;
#end