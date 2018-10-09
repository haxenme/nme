package nme.media;
#if (!flash)

import nme.Loader;
import nme.display.DisplayObject;

@:nativeProperty
class Video extends DisplayObject
{
   public var smoothing(default, set):Bool;
   public var videoHeight(default, null):Int;
   public var videoWidth(default, null):Int;

   public function new(width:Int = 320, height:Int = 240)
   {
      super(nme_video_create(width, height), "Video");
      smoothing = false;
      videoWidth = width;
      videoHeight = height;
   }

   public function load(filename:String)
   {
      nme_video_load(nmeHandle, filename);
   }

   public function play()
   {
      nme_video_play(nmeHandle);
   }

   public function clear()
   {
      nme_video_clear(nmeHandle);
   }

   private function set_smoothing(value:Bool):Bool
   {
      nme_video_set_smoothing(nmeHandle, value);
      smoothing = value;
      return value;
   }

   public function attachNetStream(inNetStream : nme.net.NetStream) : Void
   {
      // TODO:
   }


   private static var nme_video_create = Loader.load("nme_video_create", 2);
   private static var nme_video_load = Loader.load("nme_video_load", 2);
   private static var nme_video_play = Loader.load("nme_video_play", 1);
   private static var nme_video_clear = Loader.load("nme_video_clear", 1);
   private static var nme_video_set_smoothing = Loader.load("nme_video_set_smoothing", 2);
}

#else
typedef Video = flash.media.Video;
#end
