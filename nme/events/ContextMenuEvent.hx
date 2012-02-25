package nme.events;
#if js

import nme.display.InteractiveObject;

class ContextMenuEvent extends Event {
	var contextMenuOwner : flash.display.InteractiveObject;
	var mouseTarget : flash.display.InteractiveObject;
	function new(type : String, bubbles : Bool = false, cancelable : Bool = false, ?mouseTarget : InteractiveObject, ?contextMenuOwner : InteractiveObject) {
		super(type, bubbles, cancelable);
		this.mouseTarget = mouseTarget;
		this.contextMenuOwner = contextMenuOwner;
	}
	static var MENU_ITEM_SELECT : String;
	static var MENU_SELECT : String;
}

#else
typedef ContextMenuEvent = flash.events.ContextMenuEvent;
#end