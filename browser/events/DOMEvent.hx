package browser.events;
#if js


#if interop
class DOMEvent extends Event {
	
	
	public var domEvent:js.html.Event;
	
	
	public function new(type:String, domEvent:js.html.Event = null) {
		
		super(type, false, false);
		
		this.domEvent = domEvent;
		
	}
	
	
}
#end


#end