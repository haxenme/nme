package nme.media.soundmanager.io.android;

/**
 * ...
 * @author Andreas Rønning
 */

class AndroidCue implements ISoundCue
{

	public var path:String;
	public var index:Int;
	public var duration:Float;
	public function new(path:String) 
	{
		this.path = path;
		index = AndroidAudio.currentPool.load(path);
	}
	
	/* INTERFACE com.furusystems.games.audio.manager.io.ISoundCue */
	
	public function release():Void 
	{
		AndroidAudio.currentPool.unload(index);
	}
	
}