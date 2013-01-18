package browser.filters;
#if js


class GradientBevelFilter extends BitmapFilter {
	
	
	public var alphas:Array<Dynamic>;
	public var angle:Float;
	public var blurX:Float;
	public var blurY:Float;
	public var colors:Array<Dynamic>;
	public var distance:Float;
	public var knockout:Bool;
	public var quality:Int;
	public var ratios:Array<Dynamic>;
	public var strength:Float;
	public var type:String;
	
	
	public function new(?distance:Float, ?angle:Float, ?colors:Array<Dynamic>, ?alphas:Array<Dynamic>, ?ratios:Array<Dynamic>, ?blurX:Float, ?blurY:Float, ?strength:Float, ?quality:Int, ?type:String, ?knockout:Bool) {
		
		super("GradientBevelFilter");
		
		this.distance = distance;
		this.angle = angle;
		this.colors = colors;
		this.alphas = alphas;
		this.ratios = ratios;
		this.blurX = blurX;
		this.blurY = blurY;
		this.strength = strength;
		this.quality = quality;
		this.type = type;
		this.knockout = knockout;
		
	}
	
	
}


#end