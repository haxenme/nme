package browser.filters;


import browser.Html5Dom;


class BitmapFilter {
	
	
	private var _mType:String;
	private var _nmeCached:Bool;
	

	public function new (inType:String) {
		
		_mType = inType;
		
	}
	
	
	public function clone():BitmapFilter {
		
		throw "Implement in subclass. BitmapFilter::clone";
		return null;
		
	}
	
	
	public function nmePreFilter (surface:HTMLCanvasElement) {
		
		
		
	}
	
	
	public function nmeApplyFilter (surface:HTMLCanvasElement, refreshCache:Bool = false) {
		
		
		
	}
	
	
}