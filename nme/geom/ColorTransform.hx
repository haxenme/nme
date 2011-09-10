package nme.geom;


#if flash
@:native ("flash.geom.ColorTransform")
extern class ColorTransform {
	var alphaMultiplier : Float;
	var alphaOffset : Float;
	var blueMultiplier : Float;
	var blueOffset : Float;
	var color : UInt;
	var greenMultiplier : Float;
	var greenOffset : Float;
	var redMultiplier : Float;
	var redOffset : Float;
	function new(redMultiplier : Float = 1, greenMultiplier : Float = 1, blueMultiplier : Float = 1, alphaMultiplier : Float = 1, redOffset : Float = 0, greenOffset : Float = 0, blueOffset : Float = 0, alphaOffset : Float = 0) : Void;
	function concat(second : ColorTransform) : Void;
	function toString() : String;
}
#else



/**
* @author	Hugh Sanderson
* @author	Russell Weir
* @todo Check concat() mirrors flash behaviour
**/
class ColorTransform
{
	public var alphaMultiplier:Float;
	public var redMultiplier:Float;
	public var greenMultiplier:Float;
	public var blueMultiplier:Float;

	public var alphaOffset:Float;
	public var redOffset:Float;
	public var greenOffset:Float;
	public var blueOffset:Float;


	public function new(inRedMultiplier:Float = 1.0,
						inGreenMultiplier:Float = 1.0,
						inBlueMultiplier:Float = 1.0,
						inAlphaMultiplier:Float = 1.0,
						inRedOffset:Float = 0.0,
						inGreenOffset:Float = 0.0,
						inBlueOffset:Float = 0.0,
						inAlphaOffset:Float = 0.0)
	{
		redMultiplier = inRedMultiplier;
		greenMultiplier = inGreenMultiplier;
		blueMultiplier = inBlueMultiplier;
		alphaMultiplier = inAlphaMultiplier;
		redOffset = inRedOffset;
		greenOffset = inGreenOffset;
		blueOffset = inBlueOffset;
		alphaOffset = inAlphaOffset;
	}

	public function concat(second:ColorTransform) : Void {
		redMultiplier += second.redMultiplier;
		greenMultiplier += second.greenMultiplier;
		blueMultiplier += second.blueMultiplier;
		alphaMultiplier += second.alphaMultiplier;
	}
}
#end