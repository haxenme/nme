package browser.events;


class ErrorEvent extends TextEvent {
	
	
	public static var ERROR:String = "error";
	
	
	public function new(type : String, ?bubbles : Bool, ?cancelable : Bool, ?text : String) : Void
	{
		super(type, bubbles, cancelable);
		this.text = text;
	}
	
}
