package browser.media;
#if js


import browser.events.Event;
import browser.events.EventDispatcher;
import js.html.MediaElement;
import js.Browser;


class SoundChannel extends EventDispatcher {
	
	
	public var ChannelId(default, null):Int;
	public var leftPeak(default, null):Float;
	public var nmeAudio(default, null):MediaElement;
	public var position(default, null):Float;
	public var rightPeak(default, null):Float;
	public var soundTransform(default, set_soundTransform):SoundTransform;

	private var nmeAudioCurrentLoop:Int;
	private var nmeAudioTotalLoops:Int;
	private var nmeRemoveRef:Void->Void;
	private var nmeStartTime:Float;
	
	
	private function new():Void {
		
		super(this);
		
		ChannelId = -1;
		leftPeak = 0.;
		position = 0.;
		rightPeak = 0.;
		
		nmeAudioCurrentLoop = 1;
		nmeAudioTotalLoops = 1;
		
	}
	
	
	public static function nmeCreate(src:String, startTime:Float = 0.0, loops:Int = 0, sndTransform:SoundTransform = null, removeRef:Void->Void):SoundChannel {
		
		var channel = new SoundChannel();
		
		channel.nmeAudio = cast Browser.document.createElement("audio");
		channel.nmeRemoveRef = removeRef;
		channel.nmeAudio.addEventListener("ended", cast channel.__onSoundChannelFinished, false);
		channel.nmeAudio.addEventListener("seeked", cast channel.__onSoundSeeked, false);
		channel.nmeAudio.addEventListener("stalled", cast channel.__onStalled, false);
		channel.nmeAudio.addEventListener("progress", cast channel.__onProgress, false);
		
		if (loops > 0) {
			
			channel.nmeAudioTotalLoops = loops;
			// webkit-specific 
			channel.nmeAudio.loop = true;
			
		}
		
		channel.nmeStartTime = startTime;
		
		if (startTime > 0.) {
			
			var onLoad = null;
			
			onLoad = function(_) { 
				
				channel.nmeAudio.currentTime = channel.nmeStartTime; 
				channel.nmeAudio.play();
				channel.nmeAudio.removeEventListener("canplaythrough", cast onLoad, false);
				
			}
			
			channel.nmeAudio.addEventListener("canplaythrough", cast onLoad, false);
			
		} else {
			
			channel.nmeAudio.autoplay = true;
			
		}
		
		channel.nmeAudio.src = src;
		
		// note: the following line seems to crash completely on most browsers,
		// maybe because the sound isn't loaded ?
		
		//if (startTime > 0.) channel.nmeAudio.currentTime = startTime;
		
		return channel;
		
	}
	
	
	public function stop():Void {
		
		if (nmeAudio != null) {
			
			nmeAudio.pause();
			nmeAudio = null;
			if (nmeRemoveRef != null) nmeRemoveRef();
			
		}
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private function __onProgress(evt:Event):Void {
		
		trace("sound progress: " + evt);
		
	}
	
	
	private function __onSoundChannelFinished(evt:Event):Void {
		
		if (nmeAudioCurrentLoop >= nmeAudioTotalLoops) {
			
			nmeAudio.removeEventListener("ended", cast __onSoundChannelFinished, false);
			nmeAudio.removeEventListener("seeked", cast __onSoundSeeked, false);
			nmeAudio.removeEventListener("stalled", cast __onStalled, false);
			nmeAudio.removeEventListener("progress", cast __onProgress, false);
			nmeAudio = null;
			
			var evt = new Event(Event.COMPLETE);
			evt.target = this;
			dispatchEvent(evt);
			
			if (nmeRemoveRef != null) {
				
				nmeRemoveRef();
				
			}
			
		} else {
			
			// firefox-specific
			nmeAudio.currentTime = nmeStartTime;
			nmeAudio.play();
			
		}
		
	}
	
	
	private function __onSoundSeeked(evt:Event):Void {
		
		if (nmeAudioCurrentLoop >= nmeAudioTotalLoops) {
			
			nmeAudio.loop = false;
			stop();
			
		} else {
			
			nmeAudioCurrentLoop++;
			
		}
		
	}
	
	
	private function __onStalled(evt:Event):Void {
		
		trace("sound stalled");
		
		if (nmeAudio != null) {
			
			nmeAudio.load();
			
		}
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function set_soundTransform(v:SoundTransform):SoundTransform {
		
		nmeAudio.volume = v.volume;
		return this.soundTransform = v;
		
	}
	
	
}


#end