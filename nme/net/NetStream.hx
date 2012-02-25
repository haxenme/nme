package nme.net;
#if js


//import haxe.remoting.Connection;
import nme.events.NetStatusEvent;
import haxe.Timer;
import nme.display.Graphics;
import nme.events.Event;
import nme.events.EventDispatcher;
import nme.media.VideoElement;
import nme.Lib;

import Html5Dom;

class NetStream extends EventDispatcher {
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
	var soundTransform : flash.media.SoundTransform;
	var time(default,null) : Float;
	var videoCodec(default,null) : UInt;
	*/
	public var bufferTime :Float;
	
	public var play:Dynamic;
	public var client:Dynamic;
	private static inline var fps:Int = 30;

	public var jeashVideoElement(default, null):HTMLMediaElement;
	
	private var timer:Timer;

	/* events */
	public static inline var BUFFER_UPDATED:String = "nme.net.NetStream.updated";
	
	public static inline var CODE_PLAY_STREAMNOTFOUND:String 	= "NetStream.Play.StreamNotFound";
	public static inline var CODE_BUFFER_EMPTY:String 			= "NetStream.Buffer.Empty";
	public static inline var CODE_BUFFER_FULL:String 			= "NetStream.Buffer.Full";
	public static inline var CODE_BUFFER_FLUSH:String 			= "NetStream.Buffer.Flush";
	public static inline var CODE_BUFFER_START:String 			= "NetStream.Play.Start";
	public static inline var CODE_BUFFER_STOP:String 			= "NetStream.Play.Stop";
	
	public function new(connection:NetConnection) : Void
	{	
		super();

		jeashVideoElement = cast js.Lib.document.createElement("video");

		play = Reflect.makeVarArgs(jeashPlay);
		
	}
	
	function jeashPlay(val:Array<Dynamic>) : Void
	{
		var url = Std.string(val[0]);
		jeashVideoElement.src = url;
	}
	
	/*
	todo:
	function attachAudio(microphone : flash.media.Microphone) : Void;
	function attachCamera(theCamera : flash.media.Camera, ?snapshotMilliseconds : Int) : Void;
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