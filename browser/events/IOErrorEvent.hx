package browser.events;
#if js


class IOErrorEvent extends Event {
	
	
	public static var IO_ERROR = "ioError";
	
	public var text:String;
	
	
	public function new(type:String, bubbles:Bool = false, cancelable:Bool = false, inText:String = "") {
		
		super(type, bubbles, cancelable);
		
		text = inText;
		
	}
	
	
}


#end