package nme.events;


#if flash
@:native ("flash.events.IEventDispatcher")
extern interface IEventDispatcher {
	function addEventListener(type : String, listener : Dynamic -> Void, useCapture : Bool = false, priority : Int = 0, useWeakReference : Bool = false) : Void;
	function dispatchEvent(event : Event) : Bool;
	function hasEventListener(type : String) : Bool;
	function removeEventListener(type : String, listener : Dynamic -> Void, useCapture : Bool = false) : Void;
	function willTrigger(type : String) : Bool;
}
#else



typedef Function = Dynamic->Void;

interface IEventDispatcher
{
	public function addEventListener(type:String, listener:Function,
	         useCapture:Bool = false, priority:Int = 0,
		 useWeakReference:Bool = false ):Void;

	public function dispatchEvent(event:Event):Bool;
	public function hasEventListener(type:String):Bool;
	public function removeEventListener(type:String, listener:Function, useCapture:Bool= false):Void;
	public function willTrigger(type:String):Bool;

}
#end