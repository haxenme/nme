package nme.media;

import nme.Loader;
import nme.display.BitmapData;
import nme.events.StatusEvent;
import nme.events.Event;
import nme.NativeHandle;

@:nativeProperty
class Camera extends nme.events.EventDispatcher
{
   public static inline var CAMERA_UNMUTED = "Camera.unmuted";
   public static inline var CAMERA_MUTED = "Camera.muted";

   static var cameraMap:Map<String,Camera>;

   public var bitmapData(default,null):BitmapData;
   public var errorString(default,null):String;
   public var width(default,null):Int;
   public var height(default,null):Int;
   public var nmeHandle:NativeHandle;
   // isSupported

   private function new(inHandle:Dynamic)
   {
      super();
      width = 0;
      height = 0;
      nmeHandle = inHandle;
      bitmapData = null;
   }


   public static function getCamera(name:String="default") : Camera
   {
      if (cameraMap==null)
         cameraMap = new Map<String,Camera>();
      if (cameraMap.exists(name))
         return cameraMap.get(name);
      
      var handle = nme_camera_create(name);
      if (handle==null)
         return null;
      var result = new Camera(handle);
      cameraMap.set(name,result);
      nme.Lib.current.stage.addEventListener(nme.events.Event.ENTER_FRAME, result.onPoll);
      return result;
   }

   @:keep function _on_error()
   {
      var event = new StatusEvent(StatusEvent.STATUS);
      event.code = CAMERA_MUTED;
      event.level = StatusEvent.ERROR;
      dispatchEvent(event);

      nme.Lib.current.stage.removeEventListener(nme.events.Event.ENTER_FRAME, onPoll);
   }

   @:keep function _init_frame()
   {
      bitmapData = new BitmapData(width,height,true);
      var event = new StatusEvent(StatusEvent.STATUS);
      event.code = CAMERA_UNMUTED;
      event.level = StatusEvent.STATUS;
      dispatchEvent(event);
      trace("Init frame " + width + "x" + height);
      return bitmapData.nmeHandle;
   }

   @:keep function _on_frame()
   {
      var event = new Event(Event.VIDEO_FRAME);
      dispatchEvent(event);
   }

   function onPoll(_)
   {
      nme_camera_on_poll(nmeHandle,this);
   }

   private static var nme_camera_create = Loader.load("nme_camera_create", 1);
   private static var nme_camera_on_poll = Loader.load("nme_camera_on_poll", 2);
}


