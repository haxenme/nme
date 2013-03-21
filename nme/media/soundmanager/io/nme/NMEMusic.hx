package nme.media.soundmanager.io.nme;
import nme.media.soundmanager.io.IMusic;
import nme.Assets;
import nme.media.Sound;
import nme.media.SoundChannel;
import nme.media.SoundTransform;


/**
 * ...
 * @author Andreas Rønning
 */

class NMEMusic implements IMusic
{
	public var channel:SoundChannel;
	public var isPlaying(get_isPlaying, null):Bool;
	public var path(get_path, null):String;
	private var _path:String;
		
	public function new() 
	{
		channel = null;
	}
	
	private function get_isPlaying():Bool
	{
		return (channel != null);
	}
	
	private function get_path():String 
	{
		return _path;
	}
	
	/* INTERFACE com.furusystems.games.audio.manager.io.IMusic */
	
	public function play(path:String, volume:Float, loop:Bool = true):Void 
	{
		if (isPlaying) {
			stop();
		}
		
		var s:Sound = Assets.getSound(path);
		if (s == null) return;
		
		channel = s.play(0, loop ? -1 : 0, new SoundTransform(volume));
		isPlaying = true;
		_path = path;
	}
	
	public function stop():Void 
	{
		if (isPlaying) { 
			channel.stop();
			channel   = null;
			isPlaying = false;
		}
	}
	
	/* INTERFACE com.furusystems.games.audio.manager.io.IMusic */
	
	public function setVolume(musicVolume:Float):Void 
	{
		if (isPlaying) {
			var st:SoundTransform = new SoundTransform(musicVolume);
			channel.soundTransform = st;
		}
	}
	
}