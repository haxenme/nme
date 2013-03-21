package nme.ui.utils;
import nme.events.IEventDispatcher;
import nme.events.KeyboardEvent;

/**
 * Convenience class for tracking key states
 * @author Andreas Rønning
 */
class Keymanager
{
	public var keys:Map<Int, Bool>;
	public var eventSource:IEventDispatcher;
	public function new(eventSource:IEventDispatcher) 
	{
		keys = new Map<Int, Bool>();
		init(eventSource);
	}
	private function init(eventSource:IEventDispatcher):Void {
		this.eventSource = eventSource;
		eventSource.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		eventSource.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		for (i in 0...256) {
			keys.set(i, false);
		}
	}
	
	private function onKeyUp(e:KeyboardEvent):Void 
	{
		keys.set(e.keyCode, false);
	}
	
	private function onKeyDown(e:KeyboardEvent):Void 
	{
		keys.set(e.keyCode, true);
	}
	
	public inline function keyIsDown(keyCode:Int):Bool {
		return keys.get(keyCode);
	}
	
	public function dispose():Void {
		eventSource.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		eventSource.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		eventSource = null;
		keys = null;
	}
	
}