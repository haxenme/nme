package nme.events;

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
      return "Event";
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

}

