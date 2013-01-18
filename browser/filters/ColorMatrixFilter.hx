package browser.filters;
#if js


class ColorMatrixFilter extends BitmapFilter {
	
	
	public var matrix:Array<Dynamic>;
	
	
	public function new(matrix:Array<Dynamic> = null) {
		
		super("ColorMatrixFilter");
		
		this.matrix = matrix;
		
	}
	
	
}


#end