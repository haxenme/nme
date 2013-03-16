package browser.media;
#if js


import browser.events.Event;
import browser.events.EventDispatcher;
import browser.events.IOErrorEvent;
import browser.net.URLRequest;
import browser.net.URLLoader;
import browser.Lib;
import js.html.MediaElement;
import js.Browser;


@:autoBuild(nme.Assets.embedSound())
class Sound extends EventDispatcher {
	
	
	static inline var EXTENSION_MP3 = "mp3";
	static inline var EXTENSION_OGG = "ogg";
	static inline var EXTENSION_WAV = "wav";
	static inline var EXTENSION_AAC = "aac";
	static inline var MEDIA_TYPE_MP3 = "audio/mpeg";
	static inline var MEDIA_TYPE_OGG = "audio/ogg; codecs=\"vorbis\"";
	static inline var MEDIA_TYPE_WAV = "audio/wav; codecs=\"1\"";
	static inline var MEDIA_TYPE_AAC = "audio/mp4; codecs=\"mp4a.40.2\"";
	
	public var bytesLoaded(default, null):Int;
	public var bytesTotal(default, null):Int;
	public var id3(default, null):ID3Info;
	public var isBuffering(default, null):Bool;
	public var length(default, null):Float;
	public var url(default, null):String;
	
	private var nmeSoundCache:URLLoader;
	private var nmeSoundChannels:Map<Int, SoundChannel>;
	private var nmeSoundIdx:Int;
	private var nmeStreamUrl:String;

	
	public function new(stream:URLRequest = null, context:SoundLoaderContext = null):Void {
		
		super(this);
		
		bytesLoaded = 0;
		bytesTotal = 0;
		id3 = null;
		isBuffering = false;
		length = 0;
		url = null;
		
		nmeSoundChannels = new Map<Int, SoundChannel>();
		nmeSoundIdx = 0;
		
		if (stream != null) {
			
			load(stream, context);
		}
		
	}
	
	
	public function close():Void {
		
		
		
	}
	
	
	public function load(stream:URLRequest, context:SoundLoaderContext = null):Void {
		
		nmeLoad(stream, context);
		
	}
	
	
	private function nmeAddEventListeners():Void {
		
		nmeSoundCache.addEventListener(Event.COMPLETE, nmeOnSoundLoaded);
		nmeSoundCache.addEventListener(IOErrorEvent.IO_ERROR, nmeOnSoundLoadError);
		
	}
	
	
	public static function nmeCanPlayMime(mime:String):Bool {
		
		var audio:MediaElement = cast Browser.document.createElement("audio");
		
		var playable = function(ok:String) {
			
			if (ok != "" && ok != "no") return true; else return false;
		}
		
		//return playable(audio.canPlayType(mime));
		return playable(audio.canPlayType(mime, null));
		
	}
	
	
	public static function nmeCanPlayType(extension:String):Bool {
		
		var mime = nmeMimeForExtension(extension);
		if (mime == null) return false;
		return nmeCanPlayMime(mime);
		
	}
	
	
	public function nmeLoad(stream:URLRequest, context:SoundLoaderContext = null, mime:String = ""):Void {
		
		#if debug
		if (mime == null) {
			
			var url = stream.url.split("?");
			var extension = url[0].substr(url[0].lastIndexOf(".") + 1);
			mime = nmeMimeForExtension(extension);
			
		}
		
		if (mime == null || !nmeCanPlayMime(mime))
			trace("Warning: '" + stream.url + "' with type '" + mime + "' may not play on this browser.");
		#end
		
		nmeStreamUrl = stream.url;
		
		// initiate a network request, so the resource is cached by the browser
		try {
			
			nmeSoundCache = new URLLoader();
			nmeAddEventListeners();
			nmeSoundCache.load(stream);
			
		} catch(e:Dynamic) {
			
			#if debug
			trace("Warning: Could not preload '" + stream.url + "'");
			#end
			
		}
		
	}
	
	
	private static inline function nmeMimeForExtension(extension:String):String {
		
		var mime:String = null;
		
		switch (extension) {
			
			case EXTENSION_MP3: mime = MEDIA_TYPE_MP3;
			case EXTENSION_OGG: mime = MEDIA_TYPE_OGG;
			case EXTENSION_WAV: mime = MEDIA_TYPE_WAV;
			case EXTENSION_AAC: mime = MEDIA_TYPE_AAC;
			default: mime = null;
			
		}
		
		return mime;
		
	}
	
	
	private function nmeRemoveEventListeners():Void {
		
		nmeSoundCache.removeEventListener(Event.COMPLETE, nmeOnSoundLoaded, false);
		nmeSoundCache.removeEventListener(IOErrorEvent.IO_ERROR, nmeOnSoundLoadError, false);
		
	}
	
	
	public function play(startTime:Float = 0.0, loops:Int = 0, sndTransform:SoundTransform = null):SoundChannel {
		
		if (nmeStreamUrl == null) return null;
		
		// -- GC the sound when the following closure is executed
		var self = this;
		var curIdx = nmeSoundIdx;
		var removeRef = function() {
			
			self.nmeSoundChannels.remove(curIdx);
			
		}
		// --
		
		var channel = SoundChannel.nmeCreate(nmeStreamUrl, startTime, loops, sndTransform, removeRef);
		nmeSoundChannels.set(curIdx, channel);
		nmeSoundIdx++;
		var audio = channel.nmeAudio;
		
		return channel;
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private function nmeOnSoundLoadError(evt:IOErrorEvent):Void {
		
		nmeRemoveEventListeners();
		
		#if debug
		trace("Error loading sound '" + nmeStreamUrl + "'");
		#end
		
		var evt = new IOErrorEvent(IOErrorEvent.IO_ERROR);
		dispatchEvent(evt);
		
	}
	
	
	private function nmeOnSoundLoaded(evt:Event):Void {
		
		nmeRemoveEventListeners();
		var evt = new Event(Event.COMPLETE);
		dispatchEvent(evt);
		
	}
	
	
}


#end