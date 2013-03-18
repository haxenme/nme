package browser.filters;
#if js

import browser.utils.UInt;

class BevelFilter extends BitmapFilter {
	
	
	public var angle:Float;
	public var blurX:Float;
	public var blurY:Float;
	public var distance:Float;
	public var highlightAlpha:Float;
	public var highlightColor:UInt;
	public var knockout:Bool;
	public var quality:Int;
	public var shadowAlpha:Float;
	public var shadowColor:UInt;
	public var strength:Float;
	public var type:BitmapFilterType;
	
	
	public function new(distance:Float = 0, angle:Float = 0, highlightColor:Int = 0xFF, highlightAlpha:Float = 1, shadowColor:Int = 0, shadowAlpha:Float = 1, blurX:Float = 4, blurY:Float = 4, strength:Float = 1, quality:Int = 1, type:BitmapFilterType = null, knockout:Bool = false) {
		
		super("BevelFilter");
		
		this.distance = distance;
		this.angle = angle;
		this.highlightColor = highlightColor;
		this.highlightAlpha = highlightAlpha;
		this.shadowColor = shadowColor;
		this.shadowAlpha = shadowAlpha;
		this.blurX = blurX;
		this.blurY = blurY;
		this.strength = strength;
		this.quality = quality;
		this.type = type;
		this.knockout = knockout;
		
	}
	
	
}


#end