package nme.events;
#if !flash

import nme.events.IEventDispatcher;
import nme.events.Event;
import nme.utils.WeakRef;



@:nativeProperty
class Listener 
{
   public var mID:Int;
   public var mListner:WeakRef<Function>;
   public var mPriority:Int;
   public var mUseCapture:Bool;

   private static var sIDs = 1;

   public function new(inListener:Function, inUseCapture:Bool, inPriority:Int, inUseWeakRef:Bool) 
   {
      mListner = new WeakRef<Function>(inListener,inUseWeakRef);
      mUseCapture = inUseCapture;
      mPriority = inPriority;
      mID = sIDs++;
   }

   public function dispatchEvent(event:Event) 
   {
      var ref = mListner.get();
      if (ref!=null)
         ref(event);
   }

   public function Is(inListener:Function, inCapture:Bool) 
   {
      var ref = mListner.get();
      if (ref==null)
         return false;
      return Reflect.compareMethods(ref, inListener) && mUseCapture == inCapture;
   }
}

typedef ListenerList = Array<Listener>;

#if haxe3
typedef EventMap = haxe.ds.StringMap<ListenerList>;
#else
typedef EventMap = Hash<ListenerList>;
#end


class EventDispatcher implements IEventDispatcher 
{
   /** @private */ private var nmeEventMap:EventMap;
   /** @private */ private var nmeTarget:IEventDispatcher;
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

      list.push(new Listener(listener, useCapture, priority,useWeakReference));
     
      // if pri is 0, it's fine on the end of the list. If not, might be out of order
      if ( priority != 0 ) {
         list.sort( sortEvents );
      }
   }

   public function mightRespondTo(type:String)
   {
      return nmeEventMap!=null && nmeEventMap.exists(type);
   }

   private static inline function sortEvents( a:Listener, b:Listener ):Int 
   { 
      // in theory these can be null, might be best to tread carefully
      if ( null == a && null == b ) { return 0; }
      if ( null == a ) { return -1; }
      if ( null == b ) { return 1; }
      var al = a.mListner.get();
      var bl = b.mListner.get();
      if ( null == al || null == bl ) { return 0; }
      if ( a.mPriority == b.mPriority ) { 
         // if priorities are the same, ensure original order of addition is maintained
         return a.mID == b.mID ? 0 : ( a.mID > b.mID ? 1 : -1 ); 
      } else {
         // otherwise ensure higher priority listeners come first
         return a.mPriority < b.mPriority ? 1 : -1;
      }
   } 
   
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
         var listLength = list.length;
         while(idx < listLength) 
         {
            var listener = list[idx];
            var isValid = listener!=null && listener.mListner.get()!=null;

            if (!isValid)
            {
               // Lost reference - so we can remove listener. No need to move idx...
               list.splice(idx, 1);
               listLength = list.length;
            }
            else 
            {
               if (listener.mUseCapture == capture) 
               {
                  listener.dispatchEvent(event);
                  if (event.nmeGetIsCancelledNow())
                     return true;
               }

               idx++;
            }
         }

         return true;
      }

      return false;
   }

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
      if (h != null) 
      {
         for(item in h) 
         {
            if (item != null) return true;
         }
      }

      return false;
   }

   public function removeEventListener(type:String, listener:Function, capture:Bool = false):Void 
   {
      if (nmeEventMap == null)
         return;

      if (!nmeEventMap.exists(type)) return;

      var list = nmeEventMap.get(type);
      for(i in 0...list.length) 
      {
         if (list[i] != null) 
         {
            var li = list[i];
            if (li.Is(listener, capture)) 
            {
               // Null-out here - remove on the dispatch event...
               list[i] = null;
               return;
            }
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


#else
typedef EventDispatcher = flash.events.EventDispatcher;
#end
