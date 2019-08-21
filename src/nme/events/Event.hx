package nme.events;
#if !flash

@:nativeProperty
class Event 
{
   public static inline var ACTIVATE = "activate";
   public static inline var ADDED = "added";
   public static inline var ADDED_TO_STAGE = "addedToStage";
   public static inline var CANCEL = "cancel";
   public static inline var CHANGE = "change";
   public static inline var CLOSE = "close";
   public static inline var COMPLETE = "complete";
   public static inline var CONNECT = "connect";
   public static inline var CONTEXT3D_CREATE = "context3DCreate";
   public static inline var CONTEXT3D_LOST = "context3DLost";
   public static inline var DEACTIVATE = "deactivate";
   public static inline var ENTER_FRAME = "enterFrame";
   public static inline var ID3 = "id3";
   public static inline var INIT = "init";
   public static inline var MOUSE_LEAVE = "mouseLeave";
   public static inline var OPEN = "open";
   public static inline var REMOVED = "removed";
   public static inline var REMOVED_FROM_STAGE = "removedFromStage";
   public static inline var RENDER = "render";
   public static inline var RESIZE = "resize";
   public static inline var SCROLL = "scroll";
   public static inline var SELECT = "select";
   public static inline var SOUND_COMPLETE = "soundComplete";
   public static inline var TAB_CHILDREN_CHANGE = "tabChildrenChange";
   public static inline var TAB_ENABLED_CHANGE = "tabEnabledChange";
   public static inline var TAB_INDEX_CHANGE = "tabIndexChange";
   public static inline var UNLOAD = "unload";
   public static inline var VIDEO_FRAME = "videoFrame";
   public static inline var DPI_CHANGED = "dpiChanged";

   public var bubbles(get, never):Bool;
   public var cancelable(get, never):Bool;
   public var currentTarget(get, set):Dynamic;
   public var eventPhase(get, never):Int;
   public var target(get, set):Dynamic;
   public var type(get, never):String;


   private var _bubbles : Bool;
   private var _cancelable : Bool;
   private var _currentTarget : Dynamic;
   private var _eventPhase : Int;
   private var _target : Dynamic;
   private var _type : String;
   private var nmeIsCancelled:Bool;
   private var nmeIsCancelledNow:Bool;

   public var clickCancelled:Bool;

   public function new(type:String, bubbles:Bool = false, cancelable:Bool = false) 
   {
      _type = type;
      _bubbles = bubbles;
      _cancelable = cancelable;
      nmeIsCancelled = false;
      nmeIsCancelledNow = false;
      clickCancelled = false;
      _target = null;
      _currentTarget = null;
      _eventPhase = EventPhase.AT_TARGET;
   }

   public function clone():Event 
   {
      return new Event(type, bubbles, cancelable);
   }

   /** @private */ public function nmeGetIsCancelled() {
      return nmeIsCancelled;
   }

   /** @private */ public function nmeGetIsCancelledNow() {
      return nmeIsCancelledNow;
   }

   /** @private */ public function nmeSetPhase(inPhase:Int) {
      // For internal use only...
      _eventPhase = inPhase;
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
      return "[Event type=" + type + " bubbles=" + bubbles + " cancelable=" + cancelable + "]";
   }

   // Getters & Setters
   private function get_bubbles():Bool { return _bubbles; }
   private function get_cancelable():Bool { return _cancelable; }
   private function get_currentTarget():Dynamic { return _currentTarget; }
   private function set_currentTarget(v:Dynamic):Dynamic { _currentTarget = v; return v; }
   private function get_eventPhase():Int { return _eventPhase; }
   private function get_target():Dynamic { return _target; }
   private function set_target(v:Dynamic):Dynamic { _target = v; return v; }
   private function get_type():String { return _type; }
}

#else
typedef Event = flash.events.Event;
#end
