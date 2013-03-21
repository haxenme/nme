package nme.media.soundmanager.io;

/**
 * ...
 * @author Andreas Rønning
 */

interface IMusic 
{

	function play(path:String, volume:Float, loop:Bool = true):Void;
	function stop():Void;
	function setVolume(musicVolume:Float):Void;
}