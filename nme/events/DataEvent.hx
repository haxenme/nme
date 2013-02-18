package nme.events;

#if display

extern class DataEvent extends TextEvent
{
    public static var DATA : String;
    public static var UPLOAD_COMPLETE_DATA;

    public var data : String;

    public function new(type : String, bubbles : Bool = false,
                        cancelable : Bool = false, data : String = "");
}

#elseif (cpp || neko)
typedef DataEvent =  neash.events.DataEvent;
#elseif js
typedef ErrorEvent = jeash.events.DataEvent;
#else
typedef ErrorEvent = flash.events.DataEvent;
#end
