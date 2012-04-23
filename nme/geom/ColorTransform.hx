package nme.geom;
#if code_completion


extern class ColorTransform {
	var alphaMultiplier : Float;
	var alphaOffset : Float;
	var blueMultiplier : Float;
	var blueOffset : Float;
	var color : Int;
	var greenMultiplier : Float;
	var greenOffset : Float;
	var redMultiplier : Float;
	var redOffset : Float;
	function new(redMultiplier : Float = 1, greenMultiplier : Float = 1, blueMultiplier : Float = 1, alphaMultiplier : Float = 1, redOffset : Float = 0, greenOffset : Float = 0, blueOffset : Float = 0, alphaOffset : Float = 0) : Void;
	function concat(second : ColorTransform) : Void;
	function toString() : String;
}


#elseif (cpp || neko)
typedef ColorTransform = neash.geom.ColorTransform;
#elseif js
typedef ColorTransform = jeash.geom.ColorTransform;
#else
typedef ColorTransform = flash.geom.ColorTransform;
#end