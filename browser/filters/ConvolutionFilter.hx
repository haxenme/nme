package browser.filters;
#if js

import browser.utils.UInt;

class ConvolutionFilter extends BitmapFilter {
	
	
	public var alpha:Float;
	public var bias:Float;
	public var clamp:Bool;
	public var color:UInt;
	public var divisor:Float;
	public var matrix:Array<Dynamic>;
	public var matrixX:Float;
	public var matrixY:Float;
	public var preserveAlpha:Bool;
	
	
	public function new(matrixX:Float = 0, matrixY:Float = 0, matrix:Array<Dynamic> = null, divisor:Float = 1, bias:Float = 0, preserveAlpha:Bool = true, clamp:Bool = true, color:Int = 0, alpha:Float = 0) {
		
		super("ConvolutionFilter");
		
		this.matrixX = matrixX;
		this.matrixY = matrixY;
		this.matrix = matrix;
		this.divisor = divisor;
		this.preserveAlpha = preserveAlpha;
		this.clamp = clamp;
		this.color = color;
		this.alpha = alpha;
		
	}
	
	
}


#end