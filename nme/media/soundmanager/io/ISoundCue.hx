package nme.media.soundmanager.io;

/**
 * ...
 * @author Andreas Rønning
 */

interface ISoundCue 
{
	var path:String;
	var index:Int;
	var duration:Float;
	function release():Void;
}