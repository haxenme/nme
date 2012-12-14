package native.filters;


class BlurFilter extends BitmapFilter {
	
	
	/** @private */ private var blurX:Float;
	/** @private */ private var blurY:Float;
	/** @private */ private var quality:Int;
	
	
	public function new (inBlurX:Float = 4.0, inBlurY:Float = 4.0, inQuality:Int = 1) {
		
		super ("BlurFilter");
		
		blurX = inBlurX;
		blurY = inBlurY;
		quality = inQuality;
		
	}
	
	
	override public function clone ():BitmapFilter {
		
		return new BlurFilter (blurX, blurY, quality);
		
	}
	
	
}