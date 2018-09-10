package nme.net;
#if (!flash)

import nme.media.StageVideo;
import nme.media.SoundTransform;

@:nativeProperty
class NetStream extends nme.events.EventDispatcher
{
   inline static var CONNECT_TO_FMS : String = "connectToFMS";
   inline static var DIRECT_CONNECTIONS : String ="directConnections";

   public var bytesTotal(get,null) : Int;
   public var bytesLoaded(get,null) : Int;
   public var decodedFrames(get,null) : Int;
   public var client:Dynamic;
   public var objectEncoding(default,null) : Int;
   public var peerStreams(get,null) : Array<Dynamic>;
   public var time(get,null) : Float;
   public var soundTransform(get,set) : SoundTransform;


   public var nmeConnection:NetConnection;
   public var nmeReceiveAudio:Bool;
   public var nmeReceiveVideo:Bool;

   public var nmeVolume:Float;
   public var nmeSoundPan:Float;
   public var nmeFilename:String;
   public var nmePaused:Bool;
   public var nmeSeek:Float;

   public var nmeAttachedVideo:StageVideo;

   public function new(?inConnection : NetConnection, ?peerID : String) : Void
   {
      super();
      nmeConnection = inConnection;
      client = null;
      nmeReceiveAudio = true;
      nmeReceiveVideo = true;
      nmeVolume = 1.0;
      nmeSoundPan = 0.0;
      objectEncoding = 0;
      nmePaused = false;
      nmeSeek = 0.0;
   }
   public function attach(inConnection : NetConnection) : Void
   {
      nmeConnection = inConnection;
   }
   public function get_time() : Float
   {
      if (nmeAttachedVideo!=null)
         return nmeAttachedVideo.nmeGetTime();
      return 0.0;
   }
   public function seek(offset : Float) : Void
   {
      nmeSeek = offset;
      if (nmeAttachedVideo!=null)
         nmeAttachedVideo.nmeSeek(offset);
   }
   public function close() : Void
   {
      if (nmeAttachedVideo!=null)
         nmeAttachedVideo.nmeDestroy();
      nmeFilename = null;
      nmeSeek = 0.0;
   }
   public function dispose() : Void { close(); }

   public function play(?inFilename : String, startSeconds : Float = 0.0, ?lenSeconds : Float = -1, ?p4 : Dynamic, ?p5 : Dynamic) : Void
   {
      nmeFilename = inFilename;
      if (nmeAttachedVideo!=null)
         nmeAttachedVideo.nmePlay(nmeFilename, startSeconds, lenSeconds);
   }
   // public function play2(param : NetStreamPlayOptions) : Void { }
   

   public function pause() : Void
   {
      nmePaused = true;
      if (nmeAttachedVideo!=null)
         nmeAttachedVideo.nmePause();
   }
   public function togglePause() : Void
   {
      nmePaused = !nmePaused;
      if (nmeAttachedVideo!=null)
         nmeAttachedVideo.nmeTogglePause();
   }
   public function resume() : Void
   {
      nmePaused = false;
      if (nmeAttachedVideo!=null)
         nmeAttachedVideo.nmeResume();
   }
   public function receiveAudio(flag : Bool) : Void
   {
      nmeReceiveAudio = flag;
   }
   public function receiveVideo(flag : Bool) : Void
   {
      nmeReceiveVideo = flag;
   }

   public function onPeerConnect(subscriber : NetStream) : Bool { return true; }

   function get_bytesTotal() : Int
   {
      if (nmeAttachedVideo!=null)
         return nmeAttachedVideo.nmeGetBytesTotal();
      return 0;
   }
   function get_bytesLoaded() : Int
   {
      if (nmeAttachedVideo!=null)
         return nmeAttachedVideo.nmeGetBytesLoaded();
      return 0;
   }
   function get_decodedFrames() : Int
   {
      if (nmeAttachedVideo!=null)
         return nmeAttachedVideo.nmeGetDecodedFrames();
      return 0;
   }
   function get_peerStreams() { return new Array<Dynamic>(); }

   function get_soundTransform() : SoundTransform
   {
      return new SoundTransform(nmeVolume, nmeSoundPan);
   }


   function set_soundTransform(inTransform:SoundTransform) : SoundTransform
   {
      nmeVolume = inTransform.volume;
      nmeSoundPan = inTransform.pan;
      if (nmeAttachedVideo!=null)
         nmeAttachedVideo.nmeSetSoundTransform(nmeVolume, nmeSoundPan);
      return inTransform;
   }


   //var checkPolicyFile : Bool;
   //var videoStreamSettings : nme.media.VideoStreamSettings;
   //function attachAudio(microphone : nme.media.Microphone) : Void;
   //function attachCamera(theCamera : nme.media.Camera, snapshotMilliseconds : Int = -1) : Void;
   //function receiveVideoFPS(FPS : Float) : Void;
   //public function publish(?name : String, ?type : String) : Void { }
   //function send(handlerName : String, ?p1 : Dynamic, ?p2 : Dynamic, ?p3 : Dynamic, ?p4 : Dynamic, ?p5 : Dynamic) : Void
}

#else
typedef NetStream = flash.net.NetStream;
#end


