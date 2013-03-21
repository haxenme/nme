package nme.media.soundmanager;
#if android
import nme.media.soundmanager.io.android.AndroidAudio;
#end


/**
 * ...
 * @author Andreas Rønning
 */

class SoundManager 
{
	public var fx:GameFX;
	public var music:GameMusic;
	
	public function new() 
	{
		#if android
			AndroidAudio.initialize();
		#end
		
		fx = new GameFX(this);
		music = new GameMusic(this);
	}
	public function update(delta:Float):Void
	{
		fx.update(delta);
		music.update(delta);
	}
	public function reset():Void {
		fx.reset();
		music.reset();
	}
	
}