package nme.events;
#if js


class DataEvent extends TextEvent {
	var data : String;
	public function new(type : String, ?bubbles : Bool, ?cancelable : Bool, ?data : String) {
		super(type, bubbles, cancelable);
		this.data = data;
	}
	public static var DATA : String;
	public static var UPLOAD_COMPLETE_DATA : String;
}


#else
typedef DataEvent = flash.events.DataEvent;
#end