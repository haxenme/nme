package native.filters;


class GlowFilter extends DropShadowFilter {
	
	
	public function new (in_color:Int = 0, in_alpha:Float = 1.0, in_blurX:Float = 6.0, in_blurY:Float = 6.0, in_strength:Float = 2.0, in_quality:Int = 1, in_inner:Bool = false, in_knockout:Bool = false) {
		
		super (0, 0, in_color, in_alpha, in_blurX, in_blurY, in_strength, in_quality, in_inner, in_knockout, false);
		
	}
	
	
}