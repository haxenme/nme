package nme.media.soundmanager.io;

/**
 * ...
 * @author Andreas Rønning
 */

class LengthMapper 
{
	public function new(input:String):Void {
		map = new Map<String,Float>();
		trace("Length map initialized");
		add(input);
	}
	
	public var map:Map<String,Float>;
	public function add(str:String):Void {
		var split:Array<String> = str.split("\n");
		for (s in split) {
			var s2:Array<String> = s.split(" ");
			map.set(s2[0], Std.parseFloat(s2[1]));
		}
	}
	
	public function get(path:String):Float 
	{
		return map.get(path);
	}
	
}