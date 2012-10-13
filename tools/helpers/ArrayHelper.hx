package;


class ArrayHelper {
	
	
	public static function concatUnique<T> (a:Array<T>, b:Array<T>):Array<T> {
		
		var concat = a.copy ();
		
		for (bValue in b) {
			
			var hasValue = false;
			
			for (aValue in a) {
				
				if (aValue == bValue) {
					
					hasValue = true;
					
				}
				
			}
			
			if (!hasValue) {
				
				concat.push (bValue);
				
			}
			
		}
		
		return concat;
		
	}
	
	
}