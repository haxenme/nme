package nme.events;
#if (cpp || neko)


import nme.events.IEventDispatcher;
import nme.events.Event;
import nme.utils.WeakRef;

enum ListenerEnum
{
   LISTENER(listener:Listener);
   WEAK_LISTENER(weak_ref:WeakRef<Listener>);
}


typedef ListenerList = Array<ListenerEnum>;

typedef EventMap = Hash<ListenerList>;

class EventDispatcher implements IEventDispatcher
{
   var nmeTarget:IEventDispatcher;
   var nmeEventMap : EventMap;

	public function new(?target : IEventDispatcher) : Void
   {
		nmeTarget = target==null ? this : target;
      nmeEventMap = null;
   }

	public function addEventListener(type:String, listener:Function,
	         useCapture:Bool = false, priority:Int = 0,
		 useWeakReference:Bool=false) :Void
	{
		if (nmeEventMap==null)
			nmeEventMap = new EventMap();
      var list = nmeEventMap.get(type);
      if (list==null)
      {
         list = new ListenerList();
         nmeEventMap.set(type,list);
      }

      var l =  new Listener(listener,useCapture,priority);
      if (useWeakReference)
      {
         list.push(WEAK_LISTENER(new WeakRef<Listener>(l)) );
      }
      else
         list.push(LISTENER(l));
	}

	public function dispatchEvent(event:Event):Bool
	{
		if (nmeEventMap==null)
			return false;
	   if(event.target == null)
         event.target = nmeTarget;
		 
		 
		  if(event.currentTarget == null)
         event.currentTarget = nmeTarget;
		 
		 
      var list = nmeEventMap.get(event.type);
      var capture = event.eventPhase==EventPhase.CAPTURING_PHASE;
      if (list!=null)
      {
         var idx = 0;
         while(idx<list.length)
         {
            var listener:Listener = null;
            var list_item = list[idx];
            switch(list_item)
            {
               case LISTENER(l) : listener = l;
               case WEAK_LISTENER(weak) : listener = weak.get();
            }

            if (listener==null)
            {
                // Lost reference - so we can remove listener. No need to move idx...
                list.splice(idx,1);
            }
            else
            {
               if (listener.mUseCapture==capture)
               {
                  listener.dispatchEvent(event);
                  if (event.nmeGetIsCancelledNow())
                     return true;
               }
               // Detect if the just used event listener was removed...
               if (idx<list.length && list_item!=list[idx])
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
	public function hasEventListener(type:String):Bool
	{
		if (nmeEventMap==null)
			return false;
		var h = nmeEventMap.get(type);
		return (h == null) ? false : (h.length > 0);
	}
	public function removeEventListener(type:String, listener:Function, capture:Bool= false):Void
	{
		if (nmeEventMap==null)
			return;

		if (!nmeEventMap.exists(type)) return;

      var list = nmeEventMap.get(type);
      for(i in 0...list.length)
      {
         var li = switch(list[i])
         {
            case LISTENER(l) : l;
            case WEAK_LISTENER(l) : l.get();
         }

         if (li.Is(listener,capture))
         {
             list.splice(i,1);
             return;
         }
      }
	}

	public function willTrigger(type:String):Bool
	{
		if (nmeEventMap==null)
			return false;
		return nmeEventMap.exists(type);
	}


	   /**
   * Creates and dispatches a typical Event.COMPLETE
   */
   public function DispatchCompleteEvent() {
      var evt = new Event(Event.COMPLETE);
      dispatchEvent(evt);
   }

   /**
   * Creates and dispatches a typical IOErrorEvent.IO_ERROR
   */
   public function DispatchIOErrorEvent() {
      var evt = new IOErrorEvent(IOErrorEvent.IO_ERROR);
      dispatchEvent(evt);
   }

}


class Listener
{
   public var mListner : Function;
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
   {
      return Reflect.compareMethods(mListner,inListener) && mUseCapture == inCapture;
   }

   public function dispatchEvent(event : Event)
   {
      mListner(event);
   }
}



#else
typedef EventDispatcher = flash.events.EventDispatcher;
#end
