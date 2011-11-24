package nme.events;
#if (cpp || neko)


class Event
{
	
	public static var ACTIVATE = "activate";
	public static var ADDED = "added";
	public static var ADDED_TO_STAGE = "addedToStage";
	public static var CANCEL = "cancel";
	public static var CHANGE = "change";
	public static var CLOSE = "close";
	public static var COMPLETE = "complete";
	public static var CONNECT = "connect";
	public static var DEACTIVATE = "deactivate";
	public static var ENTER_FRAME = "enterFrame";
	public static var GOT_INPUT_FOCUS = "gotInputFocus";
	public static var ID3 = "id3";
	public static var INIT = "init";
	public static var LOST_INPUT_FOCUS = "lostInputFocus";
	public static var MOUSE_LEAVE = "mouseLeave";
	public static var OPEN = "open";
	public static var REMOVED = "removed";
	public static var REMOVED_FROM_STAGE = "removedFromStage";
	public static var RENDER = "render";
	public static var RESIZE = "resize";
	public static var SCROLL = "scroll";
	public static var SELECT = "select";
	public static var SOUND_COMPLETE = "soundComplete";
	public static var TAB_CHILDREN_CHANGE = "tabChildrenChange";
	public static var TAB_ENABLED_CHANGE = "tabEnabledChange";
	public static var TAB_INDEX_CHANGE = "tabIndexChange";
	public static var UNLOAD = "unload";
	
	public var bubbles(nmeGetBubbles, never):Bool;
	public var cancelable(nmeGetCancelable, never):Bool;
	public var currentTarget(nmeGetCurrentTarget, nmeSetCurrentTarget):Dynamic;
	public var eventPhase(nmeGetEventPhase, never):Int;
	public var target(nmeGetTarget, nmeSetTarget):Dynamic;
	public var type(nmeGetType, never):String;

	private var _bubbles : Bool;
	private var _cancelable : Bool;
	private var _currentTarget : Dynamic;
	private var _eventPhase : Int;
	private var _target : Dynamic;
	private var _type : String;
	private var nmeIsCancelled:Bool;
	private var nmeIsCancelledNow:Bool;
	
	
	public function new(inType:String, inBubbles:Bool = false, inCancelable:Bool = false)
	{
		_type = inType;
		_bubbles = inBubbles;
		_cancelable = inCancelable;
		nmeIsCancelled = false;
		nmeIsCancelledNow = false;
		_target = null;
		_currentTarget = null;
		_eventPhase = EventPhase.AT_TARGET;
	}
	
	
	public function clone():Event
	{
		return new Event(type, bubbles, cancelable);
	}
	
	
	/**
	 * @private
	 */
	public function nmeGetIsCancelled()
	{
		return nmeIsCancelled;
	}
	
	
	/**
	 * @private
	 */
	public function nmeGetIsCancelledNow()
	{
		return nmeIsCancelledNow;
	}
	
	
	/**
	 * @private
	 */
	public function nmeSetPhase(inPhase:Int)
	{
		// For internal use only...
		_eventPhase = inPhase;
	}
	
	
	public function stopImmediatePropagation()
	{
		if (cancelable)
			nmeIsCancelledNow = nmeIsCancelled = true;
	}
	
	
	public function stopPropagation()
	{
		if (cancelable)
			nmeIsCancelled = true;
	}
	
	
	public function toString():String
	{
		return type;
	}
	
	
	
	// Getters & Setters
	
	
	
	private function nmeGetBubbles():Bool { return _bubbles; }
	private function nmeGetCancelable():Bool { return _cancelable; }
	private function nmeGetCurrentTarget():Dynamic { return _currentTarget; }
	private function nmeSetCurrentTarget(v:Dynamic):Dynamic { _currentTarget = v; return v; }
	private function nmeGetEventPhase():Int { return _eventPhase; }
	private function nmeGetTarget():Dynamic { return _target; }
	private function nmeSetTarget(v:Dynamic):Dynamic { _target = v; return v; }
	private function nmeGetType():String { return _type; }

}


#else
typedef Event = flash.events.Event;
#end