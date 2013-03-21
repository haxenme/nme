package nme.media.soundmanager.io;
import nme.utils.Property;

/**
 * ...
 * @author Andreas Rønning
 */

interface IPlayingSound 
{
	function update(delta:Float):Void;
	function dispose():Void;
	var length:Float;
	var complete:Bool;
	var pan:Property<Float>;
	var volume:Property<Float>;
	var loopcount:Property<Int>;
	var playbackRate:Property<Float>;
	var priority:Int;
	var playStartTime:Int;
	
}