package;


import haxe.ds.StringMap;


class MapHelper {
	
	
	// Should be Map, but will use StringMap for now to avoid a compile error
	
	
	public static function copy <T> (source:StringMap <T>):StringMap <T> {
		
		var target = new StringMap <T> ();
		
		for (key in source.keys ()) {
			
			target.set (key, source.get (key));
			
		}
		
		return target;
		
	}
	
	
	public static function copyKeys <T, U> (source:Map <T, U>, target:Map <T, U>):Void {
		
		for (key in source.keys ()) {
			
			target.set (key, source.get (key));
			
		}
		
	}
	
	
	public static function copyUniqueKeys <T, U> (source:Map <T, U>, target:Map <T, U>):Void {
		
		for (key in source.keys ()) {
			
			if (!target.exists (key)) {
				
				target.set (key, source.get (key));
				
			}
			
		}
		
	}
	
	
}