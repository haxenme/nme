package nme.media.soundmanager.io.android;
import nme.JNI;

/**
 * ...
 * @author Andreas Rønning
 */

class AndroidMusic implements IMusic
{
	private var jPlay:Dynamic;
	private var jStop:Dynamic;
	private var jTransform:Dynamic;

	public function new() 
	{
		trace("setting up android music");
		jPlay = JNI.createStaticMethod("org.haxe.nme.Sound", "playMusic", "(Ljava/lang/String;DDID)I");
		jStop = JNI.createStaticMethod("org.haxe.nme.Sound", "stopMusic", "(Ljava/lang/String;)V");
		jTransform = JNI.createStaticMethod("org.haxe.nme.Sound", "setMusicTransform", "(Ljava/lang/String;DD)V");
	}
	
	/* INTERFACE com.furusystems.games.audio.manager.io.IMusic */
	
	public function play(path:String, volume:Float, loop:Bool = true):Void 
	{
		jPlay(path, volume, volume, loop?9999:0, 0);
	}
	
	public function stop():Void 
	{
		jStop("");
	}
	
	/* INTERFACE com.furusystems.games.audio.manager.io.IMusic */
	
	public function setVolume(musicVolume:Float):Void 
	{
		jTransform("", musicVolume, musicVolume);
	}
	
}