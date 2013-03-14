package nme.media.soundmanager.io.android;
import nme.media.soundmanager.io.IPlayingSound;
import nme.media.soundmanager.io.ISoundCue;

/**
 * ...
 * @author Andreas Rønning
 */

class AndroidPlayingSound implements IPlayingSound
{

	public var length:Float;
	public var complete:Bool;
	
	public var pan:Property<Float>;
	public var volume:Property<Float>;
	public var loopcount:Property<Int>;
	public var playbackRate:Property<Float>;
	
	public var priority:Int;
	private var playbackIndex:Int;
	public var playStartTime:Int;
	private var cue:ISoundCue;
	private var lVol:Float;
	private var rVol:Float;
	
	public var position:Float;
	
	private var dirty:Bool;
	public function new(cue:ISoundCue, vol:Float = 1, pan:Float = 0, loop:Int = 0, priority:Int = 0, rate:Float = 1) 
	{
		this.pan = new Property<Float>(pan);
		this.playbackRate = new Property<Float>(rate);
		this.volume = new Property<Float>(vol);
		this.loopcount = new Property<Int>(loop);
		this.cue = cue;
		position = 0;
		
		length = loop == -1?Math.POSITIVE_INFINITY:cue.duration * (loopcount.value + 1);
		//pan = 0
		var leftVol:Float = vol * (1 - pan);
		var rightVol:Float = vol * (1 + Math.min(0, pan));
		playbackIndex = AndroidAudio.currentPool.play(cue.index, leftVol, rightVol, 0, loop, rate);
	}
	
	/* INTERFACE com.furusystems.games.audio.manager.io.IPlayingSound */
	
	public function dispose():Void {
		AndroidAudio.currentPool.stop(playbackIndex);
		complete = true;
	}
	private inline function onSoundPlayed():Void 
	{
		dispose();
	}
	
	private inline function updatePan():Void {
		lVol = volume.value * (1 - pan.value);
		rVol = volume.value * (1 + Math.min(0, pan.value));
		AndroidAudio.currentPool.setVolume(playbackIndex, lVol, rVol);
	}
	
	//gather transforms and apply
	public function update(delta:Float) 
	{
		if (complete) return;
		
		if (volume.dirty || pan.dirty) {
			updatePan();
			volume.dirty = pan.dirty = false;
		}
		if (playbackRate.dirty) {
			AndroidAudio.currentPool.setRate(playbackIndex, playbackRate.value);
			playbackRate.dirty = false;
		}
		if (loopcount.dirty) {
			AndroidAudio.currentPool.setLoop(playbackIndex, loopcount.value);
			loopcount.dirty = false;
		}
		
		position += delta;
		if (position > length) {
			onSoundPlayed();
			return;
		}
	}
	
}