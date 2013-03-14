package nme.media.soundmanager;
#if android
import nme.media.soundmanager.io.android.AndroidPlayingSound;
#else
import nme.media.soundmanager.io.nme.NMEPlayingSound;
#end
import nme.media.soundmanager.io.ISoundCue;
import nme.media.soundmanager.io.IPlayingSound;

/**
 * ...
 * @author Andreas Rønning
 */

class FXChannel 
{
	public var defaultPriority:Int;
	public var playingSounds:List<IPlayingSound>;
	public var muted:Bool;
	public var mgr:GameFX;
	public var polyphony:Int;
	public function new(mgr:GameFX,polyphony:Int = 1,defaultPriority:Int = 0) 
	{
		this.polyphony = polyphony;
		this.mgr = mgr;
		this.defaultPriority = defaultPriority;
		playingSounds = new List<IPlayingSound>();
		muted = false;
	}
	public function update(delta:Float):Void {
		for (s in playingSounds) {
			s.update(delta);
			if (s.complete) playingSounds.remove(s);
		}
	}
	public function reset():Void {
		stopAllSounds();
	}
	public function play(path:String, vol:Float = 1, pan:Float = 0, loop:Int = 0, priority:Int = -1, rate:Float = 1):IPlayingSound
	{
		if (mgr.muted) return null;
		if (priority == -1) priority = defaultPriority;
		var sp:Map<String,ISoundCue> = mgr.soundPool;
		if (!(muted&&mgr.muted))
		{
			if (!sp.exists(path))
			{
				trace("No cue loaded from path: " + path);
				return null;
			} else {
				if(consolidatePolyphony(priority)){
					var cue:ISoundCue = sp.get(path);
					var s:IPlayingSound;
					#if android
					s = new AndroidPlayingSound(cue, vol * mgr.masterVolume * mgr.masterMasterVolume, pan, loop, priority, rate);
					#else
					s = new NMEPlayingSound(cue, vol * mgr.masterVolume * mgr.masterMasterVolume, pan, loop);
					#end
					playingSounds.add(s);
					return s;
				}else {
					trace("Sound could not be played due to unavailable polyphony");
					return null;
				}
			}
		} else {
			return null;
		}
	}
	private function consolidatePolyphony(priority:Int):Bool {
		//is there available polyphony?
		if (playingSounds.length < polyphony) {
			return true;
		}
		//Are there lower or same priority sounds playing? if so, kill one
		for (s in playingSounds) {
			if (s.priority <= priority) {
				s.dispose();
				return true;
			}
		}
		//there is no available polyphony, and all other currently playing sounds are higher priority. FAIL
		return false;
	}
	public function stopAllSounds():Void {
		for (s in playingSounds) {
			s.dispose();
			playingSounds.remove(s);
		}
	}
	public function setVolumeForAll(target:Float):Void {
		for (s in playingSounds) {
			s.volume.value = target;
		}
	}
	public function setPanForAll(target:Float):Void {
		for (s in playingSounds) {
			s.pan.value = target;
		}
	}
	public function stopLoops():Void 
	{
		for (s in playingSounds) {
			if (s.loopcount.value != 0) {
				s.dispose();
				playingSounds.remove(s);
			}
	
		}
	}
	
}