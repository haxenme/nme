package native.filters;


class BitmapFilter {
	
	
	/** @private */ private var type:String;
	
	
	public function new (inType) {
		
		type = inType;
		
	}
	
	
	public function clone ():BitmapFilter {
		
		throw("clone not implemented");
		return null;
		
	}
	
	
}