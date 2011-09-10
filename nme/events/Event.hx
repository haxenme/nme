package nme.events;


#if flash
@:native ("flash.events.Event")
extern class Event {
	var bubbles(default,null) : Bool;
	var cancelable(default,null) : Bool;
	var currentTarget(default,null) : Dynamic;
	var eventPhase(default,null) : EventPhase;
	var target(default,null) : Dynamic;
	var type(default,null) : String;
	function new(type : String, bubbles : Bool = false, cancelable : Bool = false) : Void;
	function clone() : Event;
	function formatToString(className : String, ?p1 : Dynamic, ?p2 : Dynamic, ?p3 : Dynamic, ?p4 : Dynamic, ?p5 : Dynamic) : String;
	function isDefaultPrevented() : Bool;
	function preventDefault() : Void;
	function stopImmediatePropagation() : Void;
	function stopPropagation() : Void;
	function toString() : String;
	static var ACTIVATE : String;
	static var ADDED : String;
	static var ADDED_TO_STAGE : String;
	static var CANCEL : String;
	static var CHANGE : String;
	@:require(flash10) static var CLEAR : String;
	static var CLOSE : String;
	static var COMPLETE : String;
	static var CONNECT : String;
	@:require(flash10) static var COPY : String;
	@:require(flash10) static var CUT : String;
	static var DEACTIVATE : String;
	static var ENTER_FRAME : String;
	@:require(flash10) static var EXIT_FRAME : String;
	@:require(flash10) static var FRAME_CONSTRUCTED : String;
	static var FULLSCREEN : String;
	static var ID3 : String;
	static var INIT : String;
	static var MOUSE_LEAVE : String;
	static var OPEN : String;
	@:require(flash10) static var PASTE : String;
	static var REMOVED : String;
	static var REMOVED_FROM_STAGE : String;
	static var RENDER : String;
	static var RESIZE : String;
	static var SCROLL : String;
	static var SELECT : String;
	@:require(flash10) static var SELECT_ALL : String;
	static var SOUND_COMPLETE : String;
	static var TAB_CHILDREN_CHANGE : String;
	static var TAB_ENABLED_CHANGE : String;
	static var TAB_INDEX_CHANGE : String;
	static var UNLOAD : String;
}
#else



class Event
{
   public var bubbles(default,null) : Bool;
   public var cancelable(default,null) : Bool;
   public var eventPhase(default,null) : Int;
   public var target : Dynamic;
   public var currentTarget : Dynamic;
   public var type(default,null) : String;

   var nmeIsCancelled:Bool;
   var nmeIsCancelledNow:Bool;
   // For internal use only...
   public function nmeSetPhase(inPhase:Int) { eventPhase = inPhase; }


   public function nmeGetIsCancelled() { return nmeIsCancelled; }
   public function nmeGetIsCancelledNow() { return nmeIsCancelledNow; }

   public function new(inType : String, inBubbles : Bool=false, inCancelable : Bool=false)
   {
      type = inType;
      bubbles = inBubbles;
      cancelable = inCancelable;
      nmeIsCancelled = false;
      nmeIsCancelledNow = false;
      target = null;
      currentTarget = null;
      eventPhase = EventPhase.AT_TARGET;
   }

   public function clone() : Event
   {
      return new Event(type,bubbles,cancelable);
   }


   public function stopImmediatePropagation()
   {
      if (cancelable)
         nmeIsCancelledNow = nmeIsCancelled = true;
   }

   public function stopPropagation()
   {
      if (cancelable)
         nmeIsCancelled = true;
   }

   public function toString():String
   {
      return type;
   }


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
   public static var SOUND_COMPLETE = "soundComplete";
   public static var TAB_CHILDREN_CHANGE = "tabChildrenChange";
   public static var TAB_ENABLED_CHANGE = "tabEnabledChange";
   public static var TAB_INDEX_CHANGE = "tabIndexChange";
   public static var UNLOAD = "unload";

   public static var GOT_INPUT_FOCUS = "gotInputFocus";
   public static var LOST_INPUT_FOCUS = "lostInputFocus";

}
#end