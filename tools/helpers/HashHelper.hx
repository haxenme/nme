package;


class HashHelper {
	
	
	public static function copy <T> (source:Hash <T>):Hash <T> {
		
		var target = new Hash <T> ();
		
		for (key in source.keys ()) {
			
			target.set (key, source.get (key));
			
		}
		
		return target;
		
	}
	
	
	public static function copyUniqueKeys <T> (source:Hash <T>, target:Hash <T>):Void {
		
		for (key in source.keys ()) {
			
			if (!target.exists (key)) {
				
				target.set (key, source.get (key));
				
			}
			
		}
		
	}
	
	
}