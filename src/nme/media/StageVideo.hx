package nme.media;

#if (!flash)

import nme.events.EventDispatcher;
import nme.Vector;
import nme.geom.Point;
import nme.geom.Rectangle;
import nme.net.NetStream;
import nme.display.Stage;
import nme.Loader;
import nme.events.NetStatusEvent;

@:nativeProperty
class StageVideo extends EventDispatcher
{
   public var colorSpaces(get,null) : Vector<String>;
   public var depth : Int;
   public var videoHeight(default,null) : Int;
   public var videoWidth(default,null) : Int;
   public var duration(default,null) : Float;

   public var viewPort(get, set) : Rectangle;
   public var pan(get,set) : Point;
   public var zoom(get,set) : Point;

   inline static var playComplete = "NetStream.Play.Complete"; // Not ios
   inline static var playSwitch = "NetStream.Play.Switch";
   inline static var playTransitionComplete = "NetStream.Play.TransitionComplete";
   inline static var playStart = "NetStream.Play.Start";
   inline static var playStop = "NetStream.Play.Stop";
   //inline static var noSupportedTrackFound = "NetStream.Play.NoSupportedTrackFound"; // Not ios
   //inline static var fileStructureInvalid = "NetStream.Play.FileStructureInvalid"; // Not ios
   inline static var playStreamNotFound = "NetStream.Play.StreamNotFound"; // Not ios
   inline static var playFailed = "NetStream.Play.Failed";  // Not ios

   inline static var seekFailed = "NetStream.Seek.Failed";  // not seekable?
   inline static var seekNotify = "NetStream.Seek.Notify";
   inline static var seekInvalidTime = "NetStream.Seek.InvalidTime";  // details contains last valid time

   inline static var failed = "NetStream.Failed"; // Other

   inline static var PAUSE = 0;
   inline static var RESUME = 1;
   inline static var TOGGLE = 2;

   inline static var PAUSE_LEN = -3;
   inline static var ALL_LEN = -1;

   inline static var PLAY_STATUS_COMPLETE = 0;
   inline static var PLAY_STATUS_SWITCH = 1;
   inline static var PLAY_STATUS_TRANSITION = 2;
   inline static var PLAY_STATUS_ERROR = 3;
   inline static var PLAY_STATUS_NOT_STARTED = 4;
   inline static var PLAY_STATUS_STARTED = 5;
   inline static var PLAY_STATUS_STOPPED = 6;

   inline static var SEEK_FINISHED_OK = 0;
   inline static var SEEK_FINISHED_EARLY = 1;
   inline static var SEEK_FINISHED_ERROR = 2;


   private var seekFrom:Float;
   private var seekCode:Int;

   var nmeHandle:Dynamic;
   var nmePan:Point;
   var nmeZoom:Point;
   var nmeViewport:Rectangle;
   var nmeNetStream:NetStream;
   var nmeStage:Stage;

   public function new(inStage:Stage)
   {
      super();
      nmeStage = inStage;
      depth = 0;
      nmePan = new Point(0,0);
      nmeZoom = new Point(1,1);
      videoWidth = 0;
      videoHeight = 0;
      duration = 0;
      nmeViewport = new Rectangle(0,0,0,0);
   }

   function get_colorSpaces()
   {
      var colorSpaces = new Vector<String>();
      colorSpaces.push("BT.709");
      return colorSpaces;
   }

   // public function attachAVStream(avStream : AVStream) : Void { }

   public function attachNetStream(inNetStream : nme.net.NetStream) : Void
   {
      if (nmeNetStream!=null)
         nmeNetStream.nmeAttachedVideo = null;
      nmeNetStream = inNetStream;
      if (nmeNetStream!=null)
      {
         nmeNetStream.nmeAttachedVideo = this;
         nmeCreate();
         if (nmeNetStream.nmeFilename!=null)
            nmePlay( nmeNetStream.nmeFilename, nmeNetStream.nmeSeek, nmeNetStream.nmePaused ? PAUSE_LEN : ALL_LEN );
      }
      else
      {
         nmeDestroy();
      }
   }
   // public function attachCamera(theCamera : Camera) : Void { }

   function get_pan() { return nmePan.clone(); }
   function set_pan(inPan:Point) : Point
   {
      nmePan = inPan.clone();
      if (nmeHandle!=null)
         nme_sv_pan(nmeHandle, inPan.x, inPan.y);
         
      return inPan;
   }

   function get_zoom() { return nmeZoom.clone(); }
   function set_zoom(inZoom:Point) : Point
   {
      nmeZoom = inZoom.clone();

      if (nmeHandle!=null)
         nme_sv_zoom(nmeHandle, nmeZoom.x, nmeZoom.y);

      return inZoom;
   }

   function get_viewPort() { return nmeViewport.clone(); }
   function set_viewPort(inVp:Rectangle) : Rectangle
   {
      nmeViewport= inVp.clone();
      if (nmeHandle!=null)
         nme_sv_viewport(nmeHandle, inVp.x, inVp.y, inVp.width, inVp.height );
      return inVp;
   }


   // You can use the NetStream API to call this like in flash, or you can just call them directly.

   public function nmeCreate()
   {
      if (nmeHandle==null)
      {
         #if android
         nme.JNI.init();
         #end
         nmeHandle = nme_sv_create(nmeStage.nmeHandle,this);
      }
      return nmeHandle!=null;
   }

   public function nmeDestroy()
   {
      if (nmeNetStream!=null && nmeNetStream.nmeAttachedVideo!=null)
         nmeNetStream.nmeAttachedVideo = null;
      nmeNetStream = null;
      
      if (nmeHandle!=null)
        nme_sv_destroy(nmeHandle);

      nmeHandle = null;
   }

   public function nmeGetTime():Float
   {
      if (nmeHandle==null)
         return 0;
      return nme_sv_get_time(nmeHandle);
   }

   public function nmeSeek(inTime:Float) : Void
   {
      if (nmeHandle==null)
         return;
      nme_sv_seek(nmeHandle,inTime);
   }

   public function nmePlay(inUrl:String, inStart:Float=0, inLength:Float=-1) : Void
   {
      if (nmeHandle==null)
         nmeCreate();
      if (nmeHandle==null)
        return;

      var localName = nme.Assets.getAssetPath(inUrl);
      nme_sv_play(nmeHandle,localName!=null ? localName : inUrl, inStart, inLength);
   }

   public function nmePause()
   {
      if (nmeHandle!=null)
        nme_sv_action(nmeHandle,PAUSE);
   }

   public function nmeTogglePause()
   {
      if (nmeHandle!=null)
        nme_sv_action(nmeHandle,TOGGLE);
   }

   public function nmeResume()
   {
      if (nmeHandle!=null)
        nme_sv_action(nmeHandle,RESUME);
   }


   public function nmeSetVolume(inVolume:Float)
   {
      if (nmeHandle!=null)
        nme_sv_set_sound_transform(nmeHandle,inVolume,0.0);
   }

   public function nmeGetBytesTotal( ) : Int
   {
      if (nmeHandle!=null && duration>0)
         return 100000;
      return 0;
   }


   public function nmeGetDecodedFrames( ) : Int
   {
      // TODO
      return 0;
   }


   public function nmeGetBytesLoaded( ) : Int
   {
      if (nmeHandle!=null && duration>0)
      {
         var percent = nme_sv_get_buffered_percent(nmeHandle);
         return Std.int(1000*percent);
      }
      return 0;
   }



   public function nmeSetSoundTransform(inVolume:Float, inRightness:Float)
   {
      if (nmeHandle!=null)
        nme_sv_set_sound_transform(nmeHandle,inVolume,inRightness);
   }

   // The native code will call this after it has used reflection to set the fields
   @:keep private function _native_meta_data()
   {
      if (nmeNetStream!=null)
      {
         var client = nmeNetStream.client;
         if (client!=null && client.onMetaData!=null)
            client.onMetaData({ width:videoWidth, height:videoHeight, duration:duration  });
      }
   }
   // Called by android listener
   @:keep private function _native_set_data(inWidth:Int, inHeight:Int, inDuration:Float)
   {
      videoWidth = inWidth;
      videoHeight = inHeight;
      duration = inDuration;
      _native_meta_data();
   }

   @:keep private function _native_play_status(inStatus:Int)
   {
      if (nmeNetStream!=null)
      {
         var client = nmeNetStream.client;
         if (client!=null && client.onPlayStatus!=null)
         {
             switch(inStatus)
             {
                 case PLAY_STATUS_COMPLETE :
                    client.onPlayStatus(playComplete);
                 case PLAY_STATUS_SWITCH :
                    client.onPlayStatus(playSwitch);
                 case PLAY_STATUS_TRANSITION :
                    client.onPlayStatus(playTransitionComplete);
             }
         }

         var info:Dynamic = null;
         switch(inStatus)
         {
              case PLAY_STATUS_NOT_STARTED :
                info = { code:playStreamNotFound  };
              case PLAY_STATUS_ERROR :
                info = { code:playFailed  };
              case PLAY_STATUS_STARTED :
                info = { code:playStart  };
              case PLAY_STATUS_STOPPED :
                info = { code:playStop  };

              case PLAY_STATUS_COMPLETE :
                 info = { code:playComplete };
              case PLAY_STATUS_SWITCH :
                 info = { code:playSwitch };
              case PLAY_STATUS_TRANSITION :
                 info = { code:playTransitionComplete };
         }
         if (info!=null)
         {
            var event = new NetStatusEvent(NetStatusEvent.NET_STATUS,false,false,info);
            nmeNetStream.dispatchEvent(event);
         }
      }
   }

   @:keep private function _native_on_seek()
   {
      if (nmeNetStream!=null)
      {
          var info:Dynamic = null;
          switch(seekCode)
          {
             case SEEK_FINISHED_OK:
                info = { code:seekNotify, seekPoint:seekFrom };
             case SEEK_FINISHED_EARLY:
                info = { code:seekInvalidTime, details:seekFrom };
             case SEEK_FINISHED_ERROR:
                info = { code:seekFailed, seekPoint:seekFrom };
          }

          if (info!=null)
          {
             var event = new NetStatusEvent(NetStatusEvent.NET_STATUS,false,false,info);
             nmeNetStream.dispatchEvent(event);
          }
      }
   }

   @:keep private function _native_on_seek_data(inCode:Int, inWhen:Float)
   {
      seekCode = inCode;
      seekFrom = inWhen;
      _native_on_seek();
   }



   private static var nme_sv_create = Loader.load("nme_sv_create", 2);
   private static var nme_sv_destroy = Loader.load("nme_sv_destroy", 1);
   private static var nme_sv_action = Loader.load("nme_sv_action", 2);
   private static var nme_sv_play = Loader.load("nme_sv_play", 4);
   private static var nme_sv_seek = Loader.load("nme_sv_seek", 2);
   private static var nme_sv_get_time = Loader.load("nme_sv_get_time", 1);
   private static var nme_sv_get_buffered_percent = Loader.load("nme_sv_get_buffered_percent", 1);
   private static var nme_sv_viewport = Loader.load("nme_sv_viewport", 5);
   private static var nme_sv_pan = Loader.load("nme_sv_pan", 3);
   private static var nme_sv_zoom = Loader.load("nme_sv_zoom", 3);
   private static var nme_sv_set_sound_transform = Loader.load("nme_sv_set_sound_transform", 3);
}

#else
typedef StageVideo = flash.net.StageVideo;
#end
