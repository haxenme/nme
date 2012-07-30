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

import jeash.Html5Dom;

/**
* @author	Russell Weir
* @author	Niel Drummond
* @todo Implement soundTransform
**/
class SoundChannel extends EventDispatcher {
	public var ChannelId(default, null):Int;
	public var leftPeak(default, null):Float;
	public var position(default, null):Float;
	public var rightPeak(default, null):Float;
	public var soundTransform(default, jeashSetSoundTransform):SoundTransform;

	var jeashAudioCurrentLoop:Int;
	var jeashAudioTotalLoops:Int;
	var jeashRemoveRef:Void->Void;
	var jeashStartTime:Float;

	public var jeashAudio (default, null):HTMLMediaElement;

	private function new():Void {
		super(this);

		ChannelId = -1;
		leftPeak = 0.;
		position = 0.;
		rightPeak = 0.;

		jeashAudioCurrentLoop = 1;
		jeashAudioTotalLoops = 1;
	}

	public static function jeashCreate(src:String, startTime:Float=0.0, loops:Int=0, sndTransform:SoundTransform=null, removeRef:Void->Void):SoundChannel {
		var channel = new SoundChannel();
		channel.jeashAudio = cast js.Lib.document.createElement("audio");
		channel.jeashRemoveRef = removeRef;
		channel.jeashAudio.addEventListener("ended", cast channel.__onSoundChannelFinished, false);
		channel.jeashAudio.addEventListener("seeked", cast channel.__onSoundSeeked, false);
		channel.jeashAudio.addEventListener("stalled", cast channel.__onStalled, false);
		channel.jeashAudio.addEventListener("progress", cast channel.__onProgress, false);
		if (loops > 0) {
			channel.jeashAudioTotalLoops = loops;
			// webkit-specific 
			channel.jeashAudio.loop = true;
		}

		channel.jeashStartTime = startTime;
		if (startTime > 0.) {
			var onLoad = null;
			onLoad = function (_) { 
				channel.jeashAudio.currentTime = channel.jeashStartTime; 
				channel.jeashAudio.play();
				channel.jeashAudio.removeEventListener("canplaythrough", cast onLoad, false);
			}
			channel.jeashAudio.addEventListener("canplaythrough", cast onLoad, false);
		} else {
			channel.jeashAudio.autoplay = true;
		}

		channel.jeashAudio.src = src;

		// note: the following line seems to crash completely on most browsers,
		// maybe because the sound isn't loaded ?

		//if (startTime > 0.) channel.jeashAudio.currentTime = startTime;

		return channel;
	}

	public function stop():Void {
		if (jeashAudio != null) {
			jeashAudio.pause();
			jeashAudio = null;
			if (jeashRemoveRef != null) jeashRemoveRef();
		}
	}

	private function jeashSetSoundTransform(v:SoundTransform):SoundTransform {
		jeashAudio.volume = v.volume;
		return this.soundTransform = v;
	}

	private function __onSoundSeeked(evt:Event):Void {
		if (jeashAudioCurrentLoop >= jeashAudioTotalLoops) {
			jeashAudio.loop = false;
			stop();
		} else {
			jeashAudioCurrentLoop++;
		}
	}

	private function __onStalled(evt:Event):Void {
		trace("sound stalled");
		if (jeashAudio != null) {
			jeashAudio.load();
		}
	}

	private function __onProgress(evt:Event):Void {
		trace("sound progress: " + evt);
	}

	private function __onSoundChannelFinished(evt:Event):Void {
		if (jeashAudioCurrentLoop >= jeashAudioTotalLoops) {
			jeashAudio.removeEventListener("ended", cast __onSoundChannelFinished, false);
			jeashAudio.removeEventListener("seeked", cast __onSoundSeeked, false);
			jeashAudio.removeEventListener("stalled", cast __onStalled, false);
			jeashAudio.removeEventListener("progress", cast __onProgress, false);
			jeashAudio = null;
			var evt = new Event(Event.COMPLETE);
			evt.target = this;
			dispatchEvent(evt);
			if (jeashRemoveRef != null)
				jeashRemoveRef();
		} else {
			// firefox-specific
			jeashAudio.currentTime = jeashStartTime;
			jeashAudio.play();
		}
	}
}