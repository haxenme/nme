package browser.events;


import browser.events.EventPhase;
import browser.events.IEventDispatcher;


class EventDispatcher implements IEventDispatcher {
	
	
	private var nmeTarget:IEventDispatcher;
	private var nmeEventMap:EventMap;
	
	
	public function new (target:IEventDispatcher = null):Void {
		
		if (target != null) {
			
			nmeTarget = target;
			
		} else {
			
			nmeTarget = this;
			
		}
		
		nmeEventMap = [];
		
	}
	
	
	public function addEventListener (type:String, inListener:Dynamic -> Void, useCapture:Bool = false, inPriority:Int = 0, useWeakReference:Bool = false):Void {
		
		var capture:Bool = (useCapture == null ? false : useCapture);
		var priority:Int = (inPriority==null ? 0 : inPriority);
		var list = getList (type);
		
		if (!existList (type)) {
			
			list = [];
			setList (type, list);
			
		}
		
		list.push (new Listener (inListener, capture, priority));
		list.sort (compareListeners);
		
	}
	
	
	private static function compareListeners (l1:Listener, l2:Listener):Int {
		
		return l1.mPriority == l2.mPriority ? 0 : (l1.mPriority > l2.mPriority? -1 : 1);
		
	}
	
	
	public function dispatchEvent (event:Event):Bool {
		
		if (event.target == null) {
			
			event.target = nmeTarget;
			
		}
		
		var capture = (event.eventPhase == EventPhase.CAPTURING_PHASE);
		
		if (existList (event.type)) {
			
			var list = getList (event.type);
			var idx = 0;
			
			while (idx < list.length) {
				
				var listener = list[idx];
				
				if (listener.mUseCapture == capture) {
					
					listener.dispatchEvent (event);
					
					if (event.nmeGetIsCancelledNow ()) {
						
						return true;
						
					}
					
				}
				
				// Detect if the just used event listener was removed...
				if (idx < list.length && listener != list[idx]) {
					
					// do not advance to next item because it looks like one was just removed
					
				} else {
					
					idx++;
					
				}
				
			}
			
			return true;
			
		}
		
		return false;
		
	}
	
	
	private function existList (type:String):Bool { 
		
		untyped return (nmeEventMap != null && nmeEventMap[type] != __js__("undefined"));
		
	}
	
	
	private function getList (type:String):ListenerList {
		
		untyped return nmeEventMap[type];
		
	}
	
	
	public function hasEventListener (type:String):Bool {
		
		return existList (type);
		
	}
	
	
	public function removeEventListener (type:String, listener:Dynamic->Void, inCapture:Bool = false):Void {
		
		if (!existList(type)) return;
		
		var list = getList (type);
		var capture:Bool = (inCapture == null ? false : inCapture);
		
		for (i in 0...list.length) {
			
			if (list[i].Is (listener, capture)) {
				
				list.splice (i, 1);
				return;
				
			}
			
		}
		
	}
	
	
	private function setList (type:String, list:ListenerList):Void { 
		
		untyped nmeEventMap[type] = list;
		
	}
	
	
	public function toString ():String { 
		
		return untyped "[ " +  this.__name__ + " ]";
		
	}
	
	
	public function willTrigger (type:String):Bool {
		
		return hasEventListener (type);
		
	}
	
	
}


class Listener {
	
	
	public var mID:Int;
	public var mListner:Dynamic->Void;
	public var mPriority:Int;
	public var mUseCapture:Bool;
	
	private static var sIDs = 1;
	
	
	public function new (inListener:Dynamic->Void, inUseCapture:Bool, inPriority:Int) {
		
		mListner = inListener;
		mUseCapture = inUseCapture;
		mPriority = inPriority;
		mID = sIDs++;
		
	}
	
	
	public function dispatchEvent (event:Event):Void {
		
		mListner (event);
		
	}
	
	
	public function Is (inListener:Dynamic->Void, inCapture:Bool):Bool {
		
		return Reflect.compareMethods (mListner, inListener) && mUseCapture == inCapture;
		
	}
	
	
}


typedef ListenerList = Array<Listener>;
typedef EventMap = Array<ListenerList>;