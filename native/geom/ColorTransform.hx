package native.geom;


class ColorTransform {
	
	
	public var alphaMultiplier:Float;
	public var alphaOffset:Float;
	public var blueMultiplier:Float;
	public var blueOffset:Float;
	public var color (get_color, set_color):Int;
	public var greenMultiplier:Float;
	public var greenOffset:Float;
	public var redMultiplier:Float;
	public var redOffset:Float;
	
	
	public function new (inRedMultiplier:Float = 1.0, inGreenMultiplier:Float = 1.0, inBlueMultiplier:Float = 1.0, inAlphaMultiplier:Float = 1.0, inRedOffset:Float = 0.0, inGreenOffset:Float = 0.0, inBlueOffset:Float = 0.0, inAlphaOffset:Float = 0.0) {
		
		redMultiplier = inRedMultiplier;
		greenMultiplier = inGreenMultiplier;
		blueMultiplier = inBlueMultiplier;
		alphaMultiplier = inAlphaMultiplier;
		redOffset = inRedOffset;
		greenOffset = inGreenOffset;
		blueOffset = inBlueOffset;
		alphaOffset = inAlphaOffset;
		
	}
	
	
	public function concat (second:ColorTransform):Void {
		
		redMultiplier += second.redMultiplier;
		greenMultiplier += second.greenMultiplier;
		blueMultiplier += second.blueMultiplier;
		alphaMultiplier += second.alphaMultiplier;
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function get_color ():Int {
		
		return ((Std.int (redOffset) << 16) | (Std.int (greenOffset) << 8) | Std.int (blueOffset));
		
	}
	
	
	private function set_color (value:Int):Int {
		
		redOffset = (value >> 16) & 0xFF;
		greenOffset = (value >> 8) & 0xFF;
		blueOffset = value & 0xFF;
		
		redMultiplier = 0;
		greenMultiplier = 0;
		blueMultiplier = 0;
		
		return color;
		
	}
	
	
}