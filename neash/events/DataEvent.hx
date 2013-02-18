package neash.events;

class DataEvent extends TextEvent
{
    public static var DATA : String = "data";
    public static var UPLOAD_COMPLETE_DATA : String = "uploadCompleteData";

    public var data : String;

    public function new(type : String, bubbles : Bool = false,
                        cancelable : Bool = false, _data : String = "") : Void
    {
        super(type, bubbles, cancelable, _data);

        data = _data;
    }

	public override function clone() : Event
	{
		return new DataEvent(type, bubbles, cancelable, data);
	}


	public override function toString() : String
	{
		return ("[DataEvent type=" + type + " bubbles=" + bubbles +
                " cancelable=" + cancelable + " data=" + data + "]");
	}
}
