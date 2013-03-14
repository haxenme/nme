package nme.media.soundmanager.io.nme;
import nme.Assets;
import nme.media.Sound;
import nme.media.soundmanager.io.ISoundCue;

/**
 * ...
 * @author Andreas Rønning
 */

class NMECue implements ISoundCue
{

	public var path:String;
	public var sound:Sound;
	public var index:Int;
	public var duration:Float;
	public function new(path:String) 
	{
		this.path = path;
		sound = Assets.getSound(path);
	}
	
	/* INTERFACE com.furusystems.games.audio.manager.io.ISoundCue */
	
	public function release():Void 
	{
		sound = null;
	}
	
}