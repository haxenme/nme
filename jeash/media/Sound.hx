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

import Html5Dom;

/**
* @author	Russell Weir
* @todo Possibly implement streaming
* @todo Review events match flash
**/
class Sound extends EventDispatcher {
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
