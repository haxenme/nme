package nme.net;

#if (cpp||neko)

class NetStream extends nme.events.EventDispatcher
{
	inline static var CONNECT_TO_FMS : String = "connectToFMS";
	inline static var DIRECT_CONNECTIONS : String ="directConnections";

	public var bytesTotal(get_bytesTotal,null) : Int;
	public var bytesLoaded(get_bytesLoaded,null) : Int;
	public var decodedFrames(get_decodedFrames,null) : Int;
   public var client:Dynamic;
	public var objectEncoding(default,null) : Int;
	public var peerStreams(get_peerStreams,null) : Array<Dynamic>;
	public var time(get_time,null) : Float;

   var nmeConnection:NetConnection;
   var nmeReceiveAudio:Bool;
   var nmeReceiveVideo:Bool;

	function new(?inConnection : NetConnection, ?peerID : String) : Void
   {
      super();
      nmeConnection = inConnection;
      client = null;
      nmeReceiveAudio = true;
      nmeReceiveVideo = true;
      objectEncoding = 0;
   }
	public function attach(inConnection : NetConnection) : Void
   {
      nmeConnection = inConnection;
   }
   public function get_time() : Float
   {
      return 0.0;
   }
	public function seek(offset : Float) : Void
   {
   }
	public function close() : Void
   {
   }
	public function dispose() : Void { close(); }
	public function play(?p1 : Dynamic, ?p2 : Dynamic, ?p3 : Dynamic, ?p4 : Dynamic, ?p5 : Dynamic) : Void
   {
   }
	// public function play2(param : NetStreamPlayOptions) : Void { }
	

	public function pause() : Void
   {
   }
	public function togglePause() : Void
   {
   }
	public function resume() : Void
   {
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

   function get_bytesTotal() { return 0; }
   function get_bytesLoaded() { return 0; }
   function get_decodedFrames() { return 0; }
   function get_peerStreams() { return new Array<Dynamic>(); }


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


