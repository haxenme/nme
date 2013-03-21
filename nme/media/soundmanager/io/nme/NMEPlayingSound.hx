package nme.media.soundmanager.io.nme;
import nme.media.SoundChannel;
import nme.media.soundmanager.io.IPlayingSound;
import nme.media.soundmanager.io.ISoundCue;
import nme.media.SoundTransform;
import nme.utils.Property;

/**
 * ...
 * @author Andreas Rønning
 */

class NMEPlayingSound implements IPlayingSound
{
	
	
	public var pan:Property<Float>;
	public var volume:Property<Float>;
	public var loopcount:Property<Int>;
	public var playbackRate:Property<Float>;
	
	
	public var channel:SoundChannel;
	public var transform:SoundTransform;
	public var playStartTime:Int;
	public var complete:Bool;
	public var length:Float;
	public var priority:Int;
	
	public var position:Float;
	public function new(cue:ISoundCue, vol:Float, pan:Float, loopcount:Int) 
	{
		this.loopcount = new Property<Int>(loopcount);
		this.volume = new Property<Float>(vol);
		this.pan = new Property<Float>(pan);
		length = loopcount==-1?Math.POSITIVE_INFINITY:cue.duration * (loopcount + 1);
		position = 0;
		
		this.channel = cast(cue, NMECue).sound.play(0, loopcount==-1?Math.ceil(Math.POSITIVE_INFINITY):loopcount, new SoundTransform(vol, pan));
	}
	public function dispose():Void {
		//trace("Dispose sound");
		channel.stop();
		complete = true;
	}
	private inline function onSoundPlayed():Void 
	{
		//trace("Sound has successfully completed playing");
		dispose();
	}
	
	//gather transforms and apply
	public function update(delta:Float) 
	{
		if (complete) return;
		var st:SoundTransform = channel.soundTransform;
		if (volume.dirty) {
			st.volume = volume.value;
			volume.dirty = false;
		}
		if (pan.dirty) {
			st.pan = pan.value;
			pan.dirty = false;
		}
		channel.soundTransform = st;
		
		position += delta;
		if (position > length) {
			onSoundPlayed();
			return;
		}
	}
	
}