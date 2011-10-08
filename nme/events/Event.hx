package nme.events;
#if (cpp || neko)


class Event
{
   public var bubbles(get_bubbles,null) : Bool;
   public var cancelable(get_cancelable,null) : Bool;
   public var eventPhase(get_eventPhase,null) : Int;
   public var target(get_target,set_target) : Dynamic;
   public var currentTarget(get_currentTarget,set_currentTarget) : Dynamic;
   public var type(get_type,null) : String;

   var _bubbles : Bool;
   var _cancelable : Bool;
   var _eventPhase : Int;
   var _target : Dynamic;
   var _currentTarget : Dynamic;
   var _type : String;
   var nmeIsCancelled:Bool;
   var nmeIsCancelledNow:Bool;
   // For internal use only...
   public function nmeSetPhase(inPhase:Int) { eventPhase = inPhase; }


   public function nmeGetIsCancelled() { return nmeIsCancelled; }
   public function nmeGetIsCancelledNow() { return nmeIsCancelledNow; }

   public function new(inType : String, inBubbles : Bool=false, inCancelable : Bool=false)
   {
      _type = inType;
      _bubbles = inBubbles;
      _cancelable = inCancelable;
      nmeIsCancelled = false;
      nmeIsCancelledNow = false;
      _target = null;
      _currentTarget = null;
      _eventPhase = EventPhase.AT_TARGET;
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

   function get_bubbles() : Bool {
      return _bubbles;
   }

   function get_cancelable() : Bool {
      return _cancelable;
   }

   function get_eventPhase() : Int {
      return _eventPhase;
   }

   function get_currentTarget() : Dynamic {
      return _currentTarget;
   }

   function set_currentTarget(v:Dynamic) : Dynamic {
      _currentTarget = v;
      return v;
   }

   function get_target() : Dynamic {
      return _target;
   }

   function set_target(v:Dynamic) : Dynamic {
      _target = v;
      return v;
   }

   function get_type() : String {
      return _type;
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


#else
typedef Event = flash.events.Event;
#end