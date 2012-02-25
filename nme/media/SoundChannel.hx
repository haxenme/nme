package nme.media;
#if (cpp || neko)


import nme.events.Event;
import nme.events.EventDispatcher;
import nme.Loader;


class SoundChannel extends EventDispatcher
{	
	
	public var leftPeak(nmeGetLeft, null):Float;
	public var rightPeak(nmeGetRight, null):Float;
	public var position(nmeGetPosition, null):Float;
	public var soundTransform(nmeGetTransform, nmeSetTransform):SoundTransform;
	
	private static var nmeIncompleteList = new Array<SoundChannel>();
	
	private var nmeHandle:Dynamic;
	private var nmeTransform:SoundTransform;
	
	
	public function new (inSoundHandle:Dynamic, startTime:Float, loops:Int, sndTransform:SoundTransform)
	{
		super();
		
		if (sndTransform != null)
		{
			nmeTransform = sndTransform.clone();
		}
		
		nmeHandle = nme_sound_channel_create(inSoundHandle, startTime, loops, nmeTransform);
		
		if (nmeHandle != null)
		{	
			nmeIncompleteList.push(this);	
		}
	}
	
	
	private function nmeCheckComplete():Bool
	{
		if (nmeHandle != null && nme_sound_channel_is_complete(nmeHandle))
		{
			nmeHandle = null;
			var complete = new Event(Event.SOUND_COMPLETE);
			dispatchEvent(complete);
			
			return true;
		}
		
		return false;
	}
	
	
	/**
	 * @private
	 */
	public static function nmeCompletePending()
	{	
		return nmeIncompleteList.length > 0;	
	}
	
	
	/**
	 * @private
	 */
	public static function nmePollComplete()
	{	
		if (nmeIncompleteList.length > 0)
		{
			var incomplete = new Array<SoundChannel>();
			
			for (channel in nmeIncompleteList)
			{
				if (!channel.nmeCheckComplete ())
				{
					incomplete.push (channel);
				}
			}
			
			nmeIncompleteList = incomplete;
		}
	}
	
	
	public function stop()
	{ 
		nme_sound_channel_stop(nmeHandle);
	}
	
	
	
	// Getters & Setters
	
	
	
	private function nmeGetLeft():Float {	return nme_sound_channel_get_left(nmeHandle); }
	private function nmeGetRight():Float { return nme_sound_channel_get_right(nmeHandle); }
	private function nmeGetPosition():Float { return nme_sound_channel_get_position(nmeHandle); }
	
	
	private function nmeGetTransform():SoundTransform
	{
		if (nmeTransform == null)
		{
			nmeTransform = new SoundTransform();
		}
		
		return nmeTransform.clone();
	}
	
	
	function nmeSetTransform(inTransform:SoundTransform):SoundTransform
	{
		nmeTransform = inTransform.clone();
		nme_sound_channel_set_transform(nmeHandle, nmeTransform);
		
		return inTransform;
	}
	
	
	
	// Native Methods
	
	
	
	private static var nme_sound_channel_is_complete = Loader.load ("nme_sound_channel_is_complete", 1);
	private static var nme_sound_channel_get_left = Loader.load ("nme_sound_channel_get_left", 1);
	private static var nme_sound_channel_get_right = Loader.load ("nme_sound_channel_get_right", 1);
	private static var nme_sound_channel_get_position = Loader.load ("nme_sound_channel_get_position", 1);
	private static var nme_sound_channel_stop = Loader.load ("nme_sound_channel_stop", 1);
	private static var nme_sound_channel_create = Loader.load ("nme_sound_channel_create", 4);
	private static var nme_sound_channel_set_transform = Loader.load ("nme_sound_channel_set_transform", 2);

}


#elseif js

import nme.events.Event;

import Html5Dom;

/**
* @author	Russell Weir
* @author	Niel Drummond
* @todo Implement soundTransform
**/
class SoundChannel extends flash.events.EventDispatcher {
	public var ChannelId(default,null) : Int;
	public var leftPeak(default,null) : Float;
	public var position(default,null) : Float;
	public var rightPeak(default,null) : Float;
	public var soundTransform(default,__setSoundTransform) : SoundTransform;

	var jeashAudioCurrentLoop:Int;
	var jeashAudioTotalLoops:Int;
	var jeashRemoveRef:Void->Void;
	var jeashStartTime:Float;

	public var jeashAudio (default, null) : HTMLMediaElement;

	private function new() : Void {
		super( this );
		ChannelId = -1;
		leftPeak = 0.;
		position = 0.;
		rightPeak = 0.;

		jeashAudioCurrentLoop = 1;
		jeashAudioTotalLoops = 1;
	}

	public static function jeashCreate(src:String, startTime : Float=0.0, loops : Int=0, sndTransform : SoundTransform=null, removeRef:Void->Void) {
		var channel = new SoundChannel();
		channel.jeashAudio = cast js.Lib.document.createElement("audio");
		channel.jeashRemoveRef = removeRef;
		channel.jeashAudio.addEventListener("ended", cast channel.__onSoundChannelFinished, false);
		channel.jeashAudio.addEventListener("seeked", cast channel.__onSoundSeeked, false);
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

	public function stop() : Void {
		if (jeashAudio != null) {
			jeashAudio.pause();
			jeashAudio = null;
			if (jeashRemoveRef != null) jeashRemoveRef();
		}
	}

	private function __setSoundTransform( v : SoundTransform ) : SoundTransform
	{
		return this.soundTransform = v;
	}

	private function __onSoundSeeked(evt : Event) {
		if (jeashAudioCurrentLoop >= jeashAudioTotalLoops) {
			jeashAudio.loop = false;
			stop();
		} else {
			jeashAudioCurrentLoop++;
		}
	}

	private function __onSoundChannelFinished(evt : Event) {
		if (jeashAudioCurrentLoop >= jeashAudioTotalLoops) {
			jeashAudio.removeEventListener("ended", cast __onSoundChannelFinished, false);
			jeashAudio.removeEventListener("seeked", cast __onSoundSeeked, false);
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

#else
typedef SoundChannel = flash.media.SoundChannel;
#end