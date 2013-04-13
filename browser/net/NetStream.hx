package browser.net;
#if js


//import haxe.remoting.Connection;
import browser.utils.UInt;
import browser.display.Graphics;
import browser.events.Event;
import browser.events.EventDispatcher;
import browser.events.NetStatusEvent;
import browser.media.VideoElement;
import browser.Lib;
import haxe.Timer;
import js.html.MediaElement;
import js.Browser;


class NetStream extends EventDispatcher {
	
	
	public static inline var BUFFER_UPDATED:String = "browser.net.NetStream.updated";
	public static inline var CODE_PLAY_STREAMNOTFOUND:String = "NetStream.Play.StreamNotFound";
	public static inline var CODE_BUFFER_EMPTY:String = "NetStream.Buffer.Empty";
	public static inline var CODE_BUFFER_FULL:String = "NetStream.Buffer.Full";
	public static inline var CODE_BUFFER_FLUSH:String = "NetStream.Buffer.Flush";
	public static inline var CODE_BUFFER_START:String = "NetStream.Play.Start";
	public static inline var CODE_BUFFER_STOP:String = "NetStream.Play.Stop";
	
	/*
	 * todo:
	var audioCodec(default,null) : UInt;
	var bufferLength(default,null) : Float;
	var bufferTime :s Float;
	var bytesLoaded(default,null) : UInt;
	var bytesTotal(default,null) : UInt;
	var checkPolicyFile : Bool;
	var client : Dynamic;
	var currentFPS(default,null) : Float;
	var decodedFrames(default,null) : UInt;
	var liveDelay(default,null) : Float;
	var objectEncoding(default,null) : UInt;
	var soundTransform : browser.media.SoundTransform;
	var time(default,null) : Float;
	var videoCodec(default,null) : UInt;
	*/
	
	public var bufferTime:Float;
	public var client:Dynamic;
	public var nmeVideoElement(default, null):MediaElement;
	public var play:Dynamic;
	
	private static inline var fps:Int = 30;
	
	private var nmeConnection: NetConnection;
	private var timer:Timer;
	
	
	public function new(connection:NetConnection):Void {
		
		super();
		
		nmeVideoElement = cast Browser.document.createElement("video");
		nmeConnection = connection;
		
		play = Reflect.makeVarArgs(nmePlay);
		
	}
	
	
	private function nmePlay(val:Array<Dynamic>):Void {
		
		var url = Std.string(val[0]);
		nmeVideoElement.src = url;
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	public function nmeBufferEmpty(e) {
		
		nmeConnection.dispatchEvent(new NetStatusEvent(NetStatusEvent.NET_STATUS, false, false, { code : CODE_BUFFER_EMPTY } ));
		
	}
	
	
	public function nmeBufferStop(e) {
		
		nmeConnection.dispatchEvent(new NetStatusEvent(NetStatusEvent.NET_STATUS, false, false, { code : CODE_BUFFER_STOP } ));
		
	}
	
	
	public function nmeBufferStart(e) {
		
		nmeConnection.dispatchEvent(new NetStatusEvent(NetStatusEvent.NET_STATUS, false, false, { code : CODE_BUFFER_START } ));
		
	}
	
	
	public function nmeNotFound(e) {
		
		nmeConnection.dispatchEvent(new NetStatusEvent(NetStatusEvent.NET_STATUS, false, false, { code : CODE_PLAY_STREAMNOTFOUND } ));
		
	}
	
	
	/*
	todo:
	function attachAudio(microphone : browser.media.Microphone) : Void;
	function attachCamera(theCamera : browser.media.Camera, ?snapshotMilliseconds : Int) : Void;
	function close() : Void;
	function pause() : Void;
	function publish(?name : String, ?type : String) : Void;
	
	function receiveVideoFPS(FPS : Float) : Void;
	function resume() : Void;
	function seek(offset : Float) : Void;
	function send(handlerName : String, ?p1 \: Dynamic, ?p2 : Dynamic, ?p3 : Dynamic, ?p4 : Dynamic, ?p5 : Dynamic ) : Void;
	function togglePause() : Void;

	#if flash10
	var maxPauseBufferTime : Float;
	var farID(default,null) : String;
	var farNonce(default,null) : String;
	var info(default,null) : NetStreamInfo;
	var nearNonce(default,null) : String;
	var peerStreams(default,null) : Array<Dynamic>;

	function onPeerConnect( subscriber : NetStream ) : Bool;
	function play2( param : NetStreamPlayOptions ) : Void;

	static var DIRECT_CONNECTIONS : String;
	#end
	*/
	
	
}


#end