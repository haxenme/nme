package nme.filters;
#if code_completion


@:final extern class DropShadowFilter extends BitmapFilter {
	var alpha : Float;
	var angle : Float;
	var blurX : Float;
	var blurY : Float;
	var color : UInt;
	var distance : Float;
	var hideObject : Bool;
	var inner : Bool;
	var knockout : Bool;
	var quality : Int;
	var strength : Float;
	function new(distance : Float = 4, angle : Float = 45, color : UInt = 0, alpha : Float = 1, blurX : Float = 4, blurY : Float = 4, strength : Float = 1, quality : Int = 1, inner : Bool = false, knockout : Bool = false, hideObject : Bool = false) : Void;
}


#elseif (cpp || neko)
typedef DropShadowFilter = neash.filters.DropShadowFilter;
#elseif js
typedef DropShadowFilter = jeash.filters.DropShadowFilter;
#else
typedef DropShadowFilter = flash.filters.DropShadowFilter;
#end