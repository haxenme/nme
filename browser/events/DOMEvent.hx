package browser.events;


#if interop
class DOMEvent extends Event {
	
	
	public var domEvent:browser.Html5Dom.Html5DomEvent;
	
	
	public function new (type:String, domEvent:browser.Html5Dom.Html5DomEvent = null) {
		
		super (type, false, false);
		
		this.domEvent = domEvent;
		
	}
	
	
}
#end
