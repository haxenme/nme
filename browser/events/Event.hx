package browser.events;


import browser.display.InteractiveObject;


class Event {
	
	
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
	public static var TAB_CHILDREN_CHANGE = "tabChildrenChange";
	public static var TAB_ENABLED_CHANGE = "tabEnabledChange";
	public static var TAB_INDEX_CHANGE = "tabIndexChange";
	public static var UNLOAD = "unload";
	public static var SOUND_COMPLETE = "soundComplete";
	
	public var bubbles (default, null):Bool;
	public var cancelable (default, null):Bool;
	public var currentTarget:Dynamic;
	public var eventPhase (default, null):Int;
	public var target:Dynamic;
	public var type (default, null):String;
	
	private var nmeIsCancelled:Bool;
	private var nmeIsCancelledNow:Bool;
	
	
	public function new (inType:String, inBubbles:Bool = false, inCancelable:Bool = false) {
		
		type = inType;
		bubbles = inBubbles;
		cancelable = inCancelable;
		nmeIsCancelled = false;
		nmeIsCancelledNow = false;
		target = null;
		currentTarget = null;
		eventPhase = EventPhase.AT_TARGET;
		
	}
	
	
	public function clone ():Event {
		
		return new Event (type, bubbles, cancelable);
		
	}
	
	
	public function nmeCreateSimilar (type:String, related:InteractiveObject = null, targ:InteractiveObject = null):Event {
		
		var result = new Event (type, bubbles, cancelable);
		
		if (targ != null) {
			
			result.target = targ;
			
		}
		
		return result;
		
	}
	
	
	public function nmeGetIsCancelled ():Bool {
		
		return nmeIsCancelled;
		
	}
	
	
	public function nmeGetIsCancelledNow ():Bool {
		
		return nmeIsCancelledNow;
		
	}
	
	
	public function nmeSetPhase (phase:Int):Void {
		
		eventPhase = phase;
		
	}
	
	
	public function stopImmediatePropagation ():Void {
		
		nmeIsCancelled = true;
		nmeIsCancelledNow = true;
		
	}
	
	
	public function stopPropagation ():Void {
		
		nmeIsCancelled = true;
		
	}
	
	
	public function toString ():String {
		
		return "[Event type=" + type + " bubbles=" + bubbles + " cancelable=" + cancelable + "]";
		
	}
	
	
}