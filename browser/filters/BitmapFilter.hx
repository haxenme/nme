package browser.filters;
#if js


import js.html.CanvasElement;


class BitmapFilter {
	
	
	private var _mType:String;
	private var _nmeCached:Bool;
	

	public function new(inType:String) {
		
		_mType = inType;
		
	}
	
	
	public function clone():BitmapFilter {
		
		throw "Implement in subclass. BitmapFilter::clone";
		return null;
		
	}
	
	
	public function nmePreFilter(surface:CanvasElement) {
		
		
		
	}
	
	
	public function nmeApplyFilter(surface:CanvasElement, refreshCache:Bool = false) {
		
		
		
	}
	
	
}


#end