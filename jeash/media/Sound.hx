/**
 * Copyright (c) 2010, Jeash contributors.
 * 
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

package jeash.media;

import jeash.events.Event;
import jeash.events.EventDispatcher;
import jeash.events.IOErrorEvent;
import jeash.net.URLRequest;
import jeash.net.URLLoader;

import jeash.Html5Dom;

class Sound extends EventDispatcher {
	public var bytesLoaded(default, null) : Int;
	public var bytesTotal(default, null) : Int;
	public var id3(default, null) : ID3Info;
	public var isBuffering(default, null) : Bool;
	public var length(default, null) : Float;
	public var url(default, null) : String;

	static inline var MEDIA_TYPE_MP3 	= "audio/mpeg";
	static inline var MEDIA_TYPE_OGG 	= "audio/ogg; codecs=\"vorbis\"";
	static inline var MEDIA_TYPE_WAV 	= "audio/wav; codecs=\"1\"";
	static inline var MEDIA_TYPE_AAC 	= "audio/mp4; codecs=\"mp4a.40.2\"";
	
	static inline var EXTENSION_MP3 	= "mp3";
	static inline var EXTENSION_OGG 	= "ogg";
	static inline var EXTENSION_WAV 	= "wav";
	static inline var EXTENSION_AAC 	= "aac";

	var jeashStreamUrl:String;
	var jeashSoundChannels : IntHash<SoundChannel>;
	var jeashSoundIdx : Int;
	var jeashSoundCache : URLLoader;

	public function new(?stream:URLRequest, ?context:SoundLoaderContext):Void {
		super(this);
		bytesLoaded = 0;
		bytesTotal = 0;
		id3 = null;
		isBuffering = false;
		length = 0;
		url = null;

		jeashSoundChannels = new IntHash();
		jeashSoundIdx = 0;

		if (stream != null)
			load(stream, context);
	}

	public static function jeashCanPlayType(extension:String):Bool {
		var mime:String = jeashMimeForExtension(extension);
		if (mime == null) return false;
		return jeashCanPlayMime(mime);
	}

	private static inline function jeashMimeForExtension(extension:String):String {
		var mime:String = null;
		switch (extension) {
			case EXTENSION_MP3:
				mime = MEDIA_TYPE_MP3;
			case EXTENSION_OGG:
				mime = MEDIA_TYPE_OGG;
			case EXTENSION_WAV:
				mime = MEDIA_TYPE_WAV;
			case EXTENSION_AAC:
				mime = MEDIA_TYPE_AAC;
			default:
				mime = null;
		}
		return mime;
	}

	public static function jeashCanPlayMime(mime:String):Bool {
		var audio : HTMLMediaElement = cast js.Lib.document.createElement("audio");
		var playable = function (ok:String) {
			if (ok != "" && ok != "no") return true; else return false;
		}
		return playable(audio.canPlayType(mime));
	}

	public function close():Void	{	}

	public function load(stream:URLRequest, ?context:SoundLoaderContext):Void {
		jeashLoad(stream, context);
	}

	public function jeashLoad(stream:URLRequest, ?context:SoundLoaderContext, ?mime:String):Void {
		#if debug
		if (mime == null) {
			var url = stream.url.split("?");
			var extension = url[0].substr(url[0].lastIndexOf(".")+1);
			mime = jeashMimeForExtension(extension);
		}
		if (mime == null || !jeashCanPlayMime(mime))
			trace("Warning: '" + stream.url + "' with type '" + mime + "' may not play on this browser.");
		#end

		jeashStreamUrl = stream.url;

		// initiate a network request, so the resource is cached by the browser
		try {
			jeashSoundCache = new URLLoader();
			jeashAddEventListeners();
			jeashSoundCache.load(stream);
		} catch (e:Dynamic) {
			#if debug
			trace("Warning: Could not preload '" + stream.url + "'");
			#end
		}
	}

	public function play(startTime:Float=0.0, loops:Int=0, sndTransform:SoundTransform=null):SoundChannel {
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

		return channel;
	}


	private function jeashAddEventListeners():Void {
		jeashSoundCache.addEventListener(Event.COMPLETE, jeashOnSoundLoaded);
		jeashSoundCache.addEventListener(IOErrorEvent.IO_ERROR, jeashOnSoundLoadError);
	}

	private function jeashRemoveEventListeners():Void {
		jeashSoundCache.removeEventListener(Event.COMPLETE, jeashOnSoundLoaded, false);
		jeashSoundCache.removeEventListener(IOErrorEvent.IO_ERROR, jeashOnSoundLoadError, false);
	}

	private function jeashOnSoundLoaded(evt:Event):Void {
		jeashRemoveEventListeners();

		var evt = new Event(Event.COMPLETE);
		dispatchEvent(evt);
	}

	private function jeashOnSoundLoadError(evt:IOErrorEvent):Void {
		jeashRemoveEventListeners();

		#if debug
		trace("Error loading sound '" + jeashStreamUrl + "'");
		#end

		var evt = new IOErrorEvent(IOErrorEvent.IO_ERROR);
		dispatchEvent(evt);
	}
}