package nme.media.soundmanager;

import nme.Assets;
import nme.errors.Error;
import nme.media.soundmanager.io.ISoundCue;
import nme.media.soundmanager.io.LengthMapper;
#if android
import nme.media.soundmanager.io.android.AndroidAudio;
typedef Cue = nme.media.soundmanager.io.android.AndroidCue;
#else
typedef Cue = nme.media.soundmanager.io.nme.NMECue;
#end

/**
 * ...
 * @author Andreas Rønning
 */

class GameFX 
{
	public var audio:SoundManager;
	public var muted:Bool;
	public var masterVolume:Float;
	public var masterMasterVolume:Float;

	public var soundPool:Map<String,ISoundCue>;
	public var mapper:LengthMapper;
	
	public var channels:Map<String,FXChannel>;
	
	public static inline var MAX_POLYPHONY:Int = 8;
	private var availablePolyphony:Int = MAX_POLYPHONY;
	
	public function new(audio:SoundManager) 
	{
		this.audio = audio;
		channels = new Map<String,FXChannel>();
		soundPool = new Map<String,ISoundCue>();
		masterVolume = 1.0;
		masterMasterVolume = 1.0;
	}
	public function createChannel(name:String, polyphony:Int, priority:Int = 0):FXChannel {
		polyphony = Std.int(Math.min(availablePolyphony, polyphony));
		if (polyphony < 1) {
			throw new Error("Ran out of available polyphony");
		}
		var chan:FXChannel = new FXChannel(this, polyphony, priority);
		channels.set(name, chan);
		availablePolyphony -= polyphony;
		return chan;
	}
	public function getChannel(name:String):FXChannel {
		return channels.get(name);
	}
	public function initLengthMap(path:String):Void {
		mapper = new LengthMapper(Assets.getText(path));
	}
	public function update(delta:Float):Void {
		for (c in channels) {
			c.update(delta);
		}
	}
	public function load(path:String):Void {
		if (soundPool.exists(path) || !isEnabled()) return;
		var newCue:ISoundCue = new Cue(path);
		newCue.duration = mapper.get(path.split("/").pop());
		soundPool.set(path,newCue);
	}
	
	public function isEnabled():Bool
	{
		return masterVolume > 0 && masterMasterVolume > 0 && !muted;
	}
	public function setMuted(m:Bool):Void
	{
		muted = m;
		if(muted) stopAllSounds();
	}
	public function stopAllSounds():Void {
		for (c in channels) {
			c.stopAllSounds();
		}
	}
	public function reset():Void {
		for (c in channels) {
			c.reset();
		}
	}
	public inline function isReady():Bool {
		#if android
			return AndroidAudio.isPoolReady();
		#else
			return true; //Dunno how sound loading on other targets work... Seem "instant"?
		#end
	}
	public function setVolumeForAll(target:Float):Void {
		for (c in channels) {
			c.setVolumeForAll(target);
		}
	}
	public function setPanForAll(target:Float):Void {
		for (c in channels) {
			c.setPanForAll(target);
		}
	}
	
	public function stopLoops():Void 
	{
		for (c in channels) {
			c.stopLoops();
		}
	}
	
}