package native.events;


class Event {
	
	
	public static var ACTIVATE = "activate";
	public static var ADDED = "added";
	public static var ADDED_TO_STAGE = "addedToStage";
	public static var CANCEL = "cancel";
	public static var CHANGE = "change";
	public static var CLOSE = "close";
	public static var COMPLETE = "complete";
	public static var CONNECT = "connect";
	public static var CONTEXT3D_CREATE = "context3DCreate";
	public static var DEACTIVATE = "deactivate";
	public static var ENTER_FRAME = "enterFrame";
	public static var ID3 = "id3";
	public static var INIT = "init";
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
	
	public var bubbles (get_bubbles, never):Bool;
	public var cancelable (get_cancelable, never):Bool;
	public var currentTarget (get_currentTarget, set_currentTarget):Dynamic;
	public var eventPhase (get_eventPhase, never):Int;
	public var target (get_target, set_target):Dynamic;
	public var type (get_type, never):String;

	/** @private */ private var _bubbles : Bool;
	/** @private */ private var _cancelable : Bool;
	/** @private */ private var _currentTarget : Dynamic;
	/** @private */ private var _eventPhase : Int;
	/** @private */ private var _target : Dynamic;
	/** @private */ private var _type : String;
	/** @private */ private var nmeIsCancelled:Bool;
	/** @private */ private var nmeIsCancelledNow:Bool;
	
	
	public function new (type:String, bubbles:Bool = false, cancelable:Bool = false) {
		
		_type = type;
		_bubbles = bubbles;
		_cancelable = cancelable;
		nmeIsCancelled = false;
		nmeIsCancelledNow = false;
		_target = null;
		_currentTarget = null;
		_eventPhase = EventPhase.AT_TARGET;
		
	}
	
	
	public function clone ():Event {
		
		return new Event (type, bubbles, cancelable);
		
	}
	
	
	/** @private */ public function nmeGetIsCancelled () {
		
		return nmeIsCancelled;
		
	}
	
	
	/** @private */ public function nmeGetIsCancelledNow () {
		
		return nmeIsCancelledNow;
		
	}
	
	
	/** @private */ public function nmeSetPhase (inPhase:Int) {
		
		// For internal use only...
		_eventPhase = inPhase;
		
	}
	
	
	public function stopImmediatePropagation () {
		
		if (cancelable)
			nmeIsCancelledNow = nmeIsCancelled = true;
		
	}
	
	
	public function stopPropagation () {
		
		if (cancelable)
			nmeIsCancelled = true;
		
	}
	
	
	public function toString ():String {
		
		return "[Event type=" + type + " bubbles=" + bubbles + " cancelable=" + cancelable + "]";
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function get_bubbles ():Bool { return _bubbles; }
	private function get_cancelable ():Bool { return _cancelable; }
	private function get_currentTarget ():Dynamic { return _currentTarget; }
	private function set_currentTarget (v:Dynamic):Dynamic { _currentTarget = v; return v; }
	private function get_eventPhase ():Int { return _eventPhase; }
	private function get_target ():Dynamic { return _target; }
	private function set_target (v:Dynamic):Dynamic { _target = v; return v; }
	private function get_type ():String { return _type; }
	
	
}