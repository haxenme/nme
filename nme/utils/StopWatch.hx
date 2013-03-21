package nme.utils;
import nme.Lib;

class Stopwatch 
{
	public static var time:Float = 0;
	public static var prevDelta:Float = 0;
	public static var timeScale:Float = 1;
	
	private static var tick:Float = 0;
	
	public static function reset():void {
		time = prevDelta = 0;
	}
	
	public static function tick(asMS:Bool = true):Float{
		prevDelta = (Lib.getTimer() - tick) * timeScale;
		time += prevDelta;
		return asMS?prevDelta:prevDelta * 0.001;
	}
}