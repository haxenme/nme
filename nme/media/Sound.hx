package nme.media;
#if (cpp || neko)


import nme.events.EventDispatcher;
import nme.events.IOErrorEvent;
import nme.net.URLRequest;
import nme.Loader;


class Sound extends EventDispatcher
{
	
	public var bytesLoaded(default,null):Int;
	public var bytesTotal(default,null):Int;
	public var id3(nmeGetID3, null):ID3Info;
	public var isBuffering(nmeGetIsBuffering, null):Bool;
	public var length(nmeGetLength, null):Float;
	public var url(default, null):String;

	private var nmeHandle:Dynamic;
	private var nmeLoading:Bool;
	
	
	public function new(?stream:URLRequest, ?context:SoundLoaderContext, forcePlayAsMusic:Bool = false)
	{
		super();
		bytesLoaded = bytesTotal = 0;
		nmeLoading = false;
		if (stream != null)
			load(stream, context, forcePlayAsMusic);
	}
	
	
	public function close()
	{
		if (nmeHandle != null)
			nme_sound_close(nmeHandle);
		nmeHandle = 0;
		nmeLoading = false;
	}
	
	
	public function load(stream:URLRequest, ?context:SoundLoaderContext, forcePlayAsMusic:Bool = false)
	{
		bytesLoaded = bytesTotal = 0;
		nmeHandle = nme_sound_from_file(stream.url, forcePlayAsMusic);
		if (nmeHandle == null)
		{
			throw ("Could not load:" + stream.url );
		}
		else
		{
			nmeLoading = true;
			nmeLoading = false;
			nmeCheckLoading();
		}
	}
	
	
	private function nmeCheckLoading()
	{
		if (nmeLoading && nmeHandle != null)
		{
			var status:Dynamic = nme_sound_get_status(nmeHandle);
			if (status == null)
				throw "Could not get sound status";
			bytesLoaded = status.bytesLoaded;
			bytesTotal = status.bytesTotal;
			nmeLoading = bytesLoaded < bytesTotal;
			if (status.error != null)
			{
				throw(status.error);
			}
		}
	}
	
	
	private function nmeOnError(msg:String):Void
	{
		dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, true, false, msg));
		nmeHandle = null;
		nmeLoading = true;
	}
	
	
	public function play(startTime:Float = 0, loops:Int = 0, ?sndTransform:SoundTransform):SoundChannel
	{
		nmeCheckLoading();
		if (nmeHandle == null || nmeLoading)
		{
			return null;
		}
		return new SoundChannel(nmeHandle, startTime, loops, sndTransform);
	}
	
	
	
	// Getters & Setters
	
	
	
	private function nmeGetID3():ID3Info
	{
		nmeCheckLoading();
		if (nmeHandle == null || nmeLoading)
			return null;
		var id3 = new ID3Info();
		nme_sound_get_id3(nmeHandle, id3);
		return id3;
	}
	
	
	private function nmeGetIsBuffering():Bool
	{
		nmeCheckLoading();
		return (nmeLoading && nmeHandle == null);
	}
	
	
	private function nmeGetLength():Float
	{
		if (nmeHandle == null || nmeLoading)
			return 0;
		return nme_sound_get_length(nmeHandle);
	}
	
	
	
	// Native Methods
	
	
	
	private static var nme_sound_from_file = Loader.load("nme_sound_from_file", 2);
	private static var nme_sound_get_id3 = Loader.load("nme_sound_get_id3", 2);
	private static var nme_sound_get_length = Loader.load("nme_sound_get_length", 1);
	private static var nme_sound_close = Loader.load("nme_sound_close", 1);
	private static var nme_sound_get_status = Loader.load("nme_sound_get_status", 1);

}


#elseif js

import nme.events.Event;
import nme.events.IOErrorEvent;
import nme.net.URLRequest;
import nme.net.URLLoader;

import Html5Dom;

/**
* @author	Russell Weir
* @todo Possibly implement streaming
* @todo Review events match flash
**/
class Sound extends flash.events.EventDispatcher {
	public var bytesLoaded(default,null) : Int;
	public var bytesTotal(default,null) : Int;
	public var id3(default,null) : ID3Info;
	public var isBuffering(default,null) : Bool;
	public var length(default,null) : Float;
	public var url(default,null) : String;

	static inline var MEDIA_TYPE_MP3 = "audio/mpeg";
	static inline var MEDIA_TYPE_OGG = "audio/ogg; codecs=\"vorbis\"";
	static inline var MEDIA_TYPE_WAV = "audio/wav; codecs=\"1\"";
	static inline var MEDIA_TYPE_AAC = "audio/mp4; codecs=\"mp4a.40.2\"";
	static inline var EXTENSION_MP3 = "mp3";
	static inline var EXTENSION_OGG = "ogg";
	static inline var EXTENSION_WAV = "wav";
	static inline var EXTENSION_AAC = "aac";

	//var jeashSoundChannels:Array<SoundChannel>;
	var jeashStreamUrl:String;
	var jeashSoundChannels : IntHash<SoundChannel>;
	var jeashSoundIdx : Int;
	var jeashSoundCache : URLLoader;

	public function new(?stream : URLRequest, ?context : SoundLoaderContext) : Void {
		super( this );
		bytesLoaded = 0;
		bytesTotal = 0;
		id3 = null;
		isBuffering = false;
		length = 0;
		url = null;

		jeashSoundChannels = new IntHash();
		jeashSoundIdx = 0;

		if(stream != null)
			load(stream, context);
	}

	/////////////////// Neash API /////////////////////////////
	public static function jeashCanPlayType(extension:String) {

			var audio : HTMLMediaElement = cast js.Lib.document.createElement("audio");
			var playable = function (ok:String)
					if (ok != "" && ok != "no") return true; else return false;

			switch (extension) {
				case EXTENSION_MP3:
					return playable(audio.canPlayType(MEDIA_TYPE_MP3));
				case EXTENSION_OGG:
					return playable(audio.canPlayType(MEDIA_TYPE_OGG));
				case EXTENSION_WAV:
					return playable(audio.canPlayType(MEDIA_TYPE_WAV));
				case EXTENSION_AAC:
					return playable(audio.canPlayType(MEDIA_TYPE_AAC));
				default:
					return false;
			}
	}

	private function jeashCreateAudio() {
	}

	/////////////////// Flash API /////////////////////////////

	public function close() : Void	{	}

	public function load(stream : URLRequest, ?context : SoundLoaderContext) : Void
	{

		//m_sound.addEventListener("audiowritten", TODO, false);
		//m_sound.addEventListener("loadstart", TODO, false);
		//m_sound.addEventListener("progress", TODO, false);
		//m_sound.addEventListener("stalled", TODO, false);
		//m_sound.addEventListener("suspend", TODO, false);
		//m_sound.addEventListener("durationchange", TODO, false);
		//m_sound.addEventListener("loadedmetadata", TODO, false);
		//m_sound.addEventListener("emptied", TODO, false);
		//m_sound.addEventListener("timeupdate", TODO, false);
		//m_sound.addEventListener("loadeddata", TODO, false);
		//m_sound.addEventListener("waiting", TODO, false);
		//m_sound.addEventListener("playing", TODO, false);
		//m_sound.addEventListener("play", TODO, false);
		//m_sound.addEventListener("canplaythrough", TODO, false);
		//m_sound.addEventListener("ratechange", TODO, false);
		//m_sound.addEventListener("pause", TODO, false);
		//m_sound.addEventListener("seeking", TODO, false);
		//m_sound.addEventListener("seeked", TODO, false);

		var url = stream.url.split("?");
		var extension = url[0].substr(url[0].lastIndexOf(".")+1);
		if (!jeashCanPlayType(extension.toLowerCase()))
			flash.Lib.trace("Warning: '" + stream.url + "' may not play on this browser.");

		jeashStreamUrl = stream.url;

		// initiate a network request, so the resource is cached by the browser
		jeashSoundCache = new URLLoader(stream);
	}

	public function play(startTime : Float=0.0, loops : Int=0, sndTransform : SoundTransform=null) : SoundChannel {
		if (jeashStreamUrl == null) return null;

		// --
		// GC the sound when the following closure is executed

		var self = this;
		var curIdx = jeashSoundIdx;
		var removeRef = function () {
			self.jeashSoundChannels.remove(curIdx);
		}

		// --

		var channel = SoundChannel.jeashCreate(jeashStreamUrl, startTime, loops, sndTransform, removeRef);
		jeashSoundChannels.set(curIdx, channel);
		jeashSoundIdx++;
		var audio = channel.jeashAudio;

		jeashAddEventListeners(audio);

		return channel;
	}


	////////////////////// Privates //////////////////////////

	private function jeashAddEventListeners(audio:HTMLMediaElement) {
		audio.addEventListener("canplay", cast __onSoundLoaded, false);
		audio.addEventListener("error", cast __onSoundLoadError, false);
		audio.addEventListener("abort", cast __onSoundLoadError, false);
	}

	private function jeashRemoveEventListeners(audio:HTMLMediaElement) {
		audio.removeEventListener("canplay", cast __onSoundLoaded, false);
		audio.removeEventListener("error", cast __onSoundLoadError, false);
		audio.removeEventListener("abort", cast __onSoundLoadError, false);

	}

	private function __onSoundLoaded(evt : Event)
	{
		var audio : HTMLMediaElement = evt.target;

		// sound is automatically played, because audio.autoplay is true

		jeashRemoveEventListeners(audio);
		
		var evt = new Event(Event.COMPLETE);
		dispatchEvent(evt);
	}

	private function __onSoundLoadError(evt : IOErrorEvent)
	{
		var audio : HTMLMediaElement = cast evt.target;

		jeashRemoveEventListeners(audio);

		flash.Lib.trace("Error loading sound '" + audio.src + "'");
		var evt = new IOErrorEvent(IOErrorEvent.IO_ERROR);
		dispatchEvent(evt);
	}

}

#else
typedef Sound = flash.media.Sound;
#end