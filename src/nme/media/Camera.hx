package nme.media;

import nme.Loader;
import nme.display.BitmapData;
import nme.events.StatusEvent;
import nme.events.Event;
import nme.NativeHandle;
import nme.PrimeLoader;
import nme.utils.ByteArray;

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
   public var name(default,null):String;

   @:keep public var depthWidth(default,null):Int;
   @:keep public var depthHeight(default,null):Int;
   @:keep public var depthData(default,null):Dynamic;
   // isSupported

   private function new(inHandle:Dynamic, inName:String )
   {
      super();
      width = 0;
      height = 0;
      nmeHandle = inHandle;
      bitmapData = null;
      name = inName;
   }

   public function close()
   {
      if (nmeHandle!=null)
         nme_camera_close(nmeHandle);
      if (cameraMap!=null)
         cameraMap.remove(name);
      nme.Lib.current.stage.removeEventListener(nme.events.Event.ENTER_FRAME, onPoll);
      nmeHandle = null;
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
      var result = new Camera(handle,name);
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

   @:keep function _init_frame_fmt(inPixelFormat:Int)
   {
      bitmapData = new BitmapData(width,height,false,0,inPixelFormat);
      var event = new StatusEvent(StatusEvent.STATUS);
      event.code = CAMERA_UNMUTED;
      event.level = StatusEvent.STATUS;
      dispatchEvent(event);
      return bitmapData.nmeHandle;
   }


   @:keep function _init_frame()
   {
      bitmapData = new BitmapData(width,height,true);
      var event = new StatusEvent(StatusEvent.STATUS);
      event.code = CAMERA_UNMUTED;
      event.level = StatusEvent.STATUS;
      dispatchEvent(event);
      return bitmapData.nmeHandle;
   }

   @:keep function _on_frame()
   {
      var event = new Event(Event.VIDEO_FRAME);
      dispatchEvent(event);
      /*
      trace('Depth: $depthWidth $depthHeight : $depthData');
      if (depthData!=null)
      {
         var f:cpp.Pointer<cpp.Float32> = cpp.Pointer.fromHandle(depthData);
         var min = 100000.0;
         var max = 0.0;
         for(i in 0...depthWidth*depthHeight)
         {
            var val = f.at(i);
            if (val<min) min = val;
            if (val>max) max = val;
         }
         trace(' dpeth range $min .. $max');
      }
      */
   }

   public function getJpegData(?buffer:ByteArray) : ByteArray
   {
      if (nmeHandle==null)
         return null;
      var size = nme_camera_get_jpeg_size(nmeHandle);
      if (size<1)
         return null;
      if (buffer==null)
         buffer = new ByteArray(size);
      else
         buffer.setAllocSize(size);

      nme_camera_get_jpeg_data(nmeHandle, buffer);

      return buffer;
   }

   public function getDepthData(?buffer:ByteArray) : ByteArray
   {
      if (nmeHandle==null)
         return null;
      var size = width*height*4;
      if (buffer==null)
         buffer = new ByteArray(size);
      else
         buffer.setAllocSize(size);

      nme_camera_get_depth(nmeHandle, buffer);

      return buffer;
   }

   function onPoll(_)
   {
      if (nmeHandle!=null)
          nme_camera_on_poll(nmeHandle,this);
   }

   private static var nme_camera_create = Loader.load("nme_camera_create", 1);
   private static var nme_camera_on_poll = Loader.load("nme_camera_on_poll", 2);
   private static var nme_camera_close = Loader.load("nme_camera_close", 1);
   private static var nme_camera_get_depth = PrimeLoader.load("nme_camera_get_depth", "oov");
   private static var nme_camera_get_jpeg_size = PrimeLoader.load("nme_camera_get_jpeg_size", "oi");
   private static var nme_camera_get_jpeg_data = PrimeLoader.load("nme_camera_get_jpeg_data", "oov");
}


