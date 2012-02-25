package nme.events;
#if (cpp || neko)


import nme.events.IEventDispatcher;
import nme.events.Event;
import nme.utils.WeakRef;


class EventDispatcher implements IEventDispatcher
{
	
	private var nmeEventMap:EventMap;
	private var nmeTarget:IEventDispatcher;
	
	
	public function new(?target:IEventDispatcher):Void
	{
		nmeTarget = target == null ? this : target;
		nmeEventMap = null;
	}
	
	
	public function addEventListener(type:String, listener:Function, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void
	{
		if (nmeEventMap == null)
			nmeEventMap = new EventMap();
		var list = nmeEventMap.get(type);
		if (list == null)
		{
			list = new ListenerList();
			nmeEventMap.set(type, list);
		}
		
		var l =  new Listener(listener, useCapture, priority);
		list.push(new WeakRef<Listener>(l, useWeakReference));
	}
	
	
	/**
	* Creates and dispatches a typical Event.COMPLETE
	* @private
	*/
	public function DispatchCompleteEvent()
	{
		var evt = new Event(Event.COMPLETE);
		dispatchEvent(evt);
	}
	
	
	public function dispatchEvent(event:Event):Bool
	{
		if (nmeEventMap == null)
			return false;
		if (event.target == null)
			event.target = nmeTarget;
		
		if (event.currentTarget == null)
			event.currentTarget = nmeTarget;
		
		var list = nmeEventMap.get(event.type);
		var capture = event.eventPhase == EventPhase.CAPTURING_PHASE;
		
		if (list != null)
		{
			var idx = 0;
			var length = list.length;
			for (i in 0...length)
			{
				var list_item = list[idx];
				var listener = list_item.get();
				
				if (listener == null)
				{
					// Lost reference - so we can remove listener. No need to move idx...
					list.splice(idx, 1);
				}
				else
				{
					if (listener.mUseCapture == capture)
					{
						listener.dispatchEvent(event);
						if (event.nmeGetIsCancelledNow())
							return true;
					}
					// Detect if the just used event listener was removed...
					if (idx < list.length && list_item != list[idx])
					{
					// do not advance to next item because it looks like one was just removed
					}
					else
						idx++;
				}
			}
			
			return true;
		}
		
		return false;
	}
	
	
	/**
	* Creates and dispatches a typical IOErrorEvent.IO_ERROR
	* @private
	*/
	public function DispatchIOErrorEvent()
	{
		var evt = new IOErrorEvent(IOErrorEvent.IO_ERROR);
		dispatchEvent(evt);
	}
	
	
	public function hasEventListener(type:String):Bool
	{
		if (nmeEventMap == null)
			return false;
		var h = nmeEventMap.get(type);
		return (h == null) ? false : (h.length > 0);
	}
	
	
	public function removeEventListener(type:String, listener:Function, capture:Bool = false):Void
	{
		if (nmeEventMap == null)
			return;
		
		if (!nmeEventMap.exists(type)) return;
		
		var list = nmeEventMap.get(type);
		for (i in 0...list.length)
		{
			var li = list[i].get();
			if (li.Is(listener, capture))
			{
				list.splice(i, 1);
				return;
			}
		}
	}
	
	
	public function toString():String
	{
		return "[object " + Type.getClassName(Type.getClass(this)) + "]";
	}
	
	
	public function willTrigger(type:String):Bool
	{
		if (nmeEventMap == null)
			return false;
		return nmeEventMap.exists(type);
	}
	
}


class Listener
{
	
	public var mID:Int;
	public var mListner:Function;
	public var mPriority:Int;
	public var mUseCapture:Bool;
	
	private static var sIDs = 1;
	

	public function new(inListener, inUseCapture, inPriority)
	{
		mListner = inListener;
		mUseCapture = inUseCapture;
		mPriority = inPriority;
		mID = sIDs++;
	}
	
	
	public function dispatchEvent(event:Event)
	{
		mListner(event);
	}
	
	
	public function Is(inListener, inCapture)
	{
		return Reflect.compareMethods(mListner, inListener) && mUseCapture == inCapture;
	}
	
}


typedef ListenerList = Array<WeakRef<Listener>>;
typedef EventMap = Hash<ListenerList>;


#elseif js

import nme.events.IEventDispatcher;
import nme.events.EventPhase;

class Listener
{
	public var mListner : Dynamic->Void;
	public var mUseCapture : Bool;
	public var mPriority : Int;
	static var sIDs = 1;
	public var mID:Int;

	public function new(inListener,inUseCapture,inPriority)
	{
		mListner = inListener;
		mUseCapture = inUseCapture;
		mPriority = inPriority;
		mID = sIDs++;
	}

	public function Is(inListener,inCapture)
		return Reflect.compareMethods(mListner, inListener) && mUseCapture == inCapture

	public function dispatchEvent(event : Event)
		mListner(event)
}

typedef ListenerList = Array<Listener>;
typedef EventMap = Array<ListenerList>;

class EventDispatcher implements IEventDispatcher
{
	var jeashTarget:IEventDispatcher;
	var jeashEventMap : EventMap;

	static private function compareListeners(l1:Listener,l2:Listener):Int{
		return l1.mPriority==l2.mPriority?0:(l1.mPriority>l2.mPriority?-1:1);
	}

	public function new(?target : IEventDispatcher) : Void
	{
		if(target != null)
			jeashTarget = target;
		else
			jeashTarget = this;
		jeashEventMap = [];
	}

	private function getList(type:String)
		untyped return jeashEventMap[type]
	
	private function setList(type:String, list:ListenerList) 
		untyped jeashEventMap[type] = list

	private function existList(type:String) 
		untyped return jeashEventMap[type] != __js__("undefined")

	public function addEventListener(type:String, inListener:Dynamic->Void,
			?useCapture:Bool /*= false*/, ?inPriority:Int /*= 0*/,
			?useWeakReference:Bool /*= false*/):Void {
		var capture:Bool = useCapture==null ? false : useCapture;
		var priority:Int = inPriority==null ? 0 : inPriority;

		var list = getList(type);

		if (!existList(type)) {
			list = new ListenerList();
			setList(type, list);
		}

		var l =  new Listener(inListener,capture,priority);
		list.push(l);
	}

	public function dispatchEvent(event : Event) : Bool {
		if(event.target == null)
			event.target = jeashTarget;

		var list = getList(event.type);
		var capture = event.eventPhase==EventPhase.CAPTURING_PHASE;
		if (existList(event.type)) {
			list.sort(compareListeners);
			
			var idx = 0;
			while(idx<list.length) {
				var listener = list[idx];
				if (listener.mUseCapture==capture) {
					listener.dispatchEvent(event);
					if (event.jeashGetIsCancelledNow())
						return true;
				}
				// Detect if the just used event listener was removed...
				if (idx<list.length && listener!=list[idx]) {
					// do not advance to next item because it looks like one was just removed
				} else
					idx++;
			}
			return true;
		}

		return false;
	}

	public function hasEventListener(type : String)
		return existList(type)

	public function removeEventListener(type : String, listener : Dynamic->Void,
			?inCapture : Bool) : Void
	{
		if (!existList(type)) return;

		var list = getList(type);
		var capture:Bool = inCapture==null ? false : inCapture;
		for(i in 0...list.length)
		{
			if (list[i].Is(listener,capture))
			{
				list.splice(i,1);
				return;
			}
		}
	}

	public function toString() 
		return untyped "[ " +  this.__name__ + " ]"

	public function willTrigger(type : String) : Bool
		return hasEventListener(type)
}

#else
typedef EventDispatcher = flash.events.EventDispatcher;
#end