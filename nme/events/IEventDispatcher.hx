package nme.events;
#if (cpp || neko)


interface IEventDispatcher
{
	
	public function addEventListener(type:String, listener:Function, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void;
	public function dispatchEvent(event:Event):Bool;
	public function hasEventListener(type:String):Bool;
	public function removeEventListener(type:String, listener:Function, useCapture:Bool = false):Void;
	public function willTrigger(type:String):Bool;

}


typedef Function = Dynamic -> Void;


#elseif js

import nme.events.Event;

interface IEventDispatcher
{
   public function addEventListener(type:String, listener:Dynamic->Void,
       ?useCapture:Bool /*= false*/, ?priority:Int /*= 0*/,
       ?useWeakReference:Bool /*= false*/):Void;

   public function dispatchEvent(event : Event) : Bool;
   public function hasEventListener(type : String) : Bool;
   public function removeEventListener(type : String, listener : Dynamic->Void,
              ?useCapture : Bool) : Void;
   public function willTrigger(type : String) : Bool;
}

#else
typedef IEventDispatcher = flash.events.IEventDispatcher;
#end