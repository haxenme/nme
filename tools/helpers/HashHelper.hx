package;


#if haxe3
import haxe.ds.StringMap;
#end


class HashHelper {
	
	
	public static function copy <T> (source:#if haxe3 StringMap #else Hash #end<T>):#if haxe3 StringMap #else Hash #end <T> {
		
		#if haxe3
		var target = new StringMap <T> ();
		#else
		var target = new Hash <T> ();
		#end
		
		for (key in source.keys ()) {
			
			target.set (key, source.get (key));
			
		}
		
		return target;
		
	}
	
	
	public static function copyUniqueKeys <T> (source:#if haxe3 StringMap #else Hash #end <T>, target:#if haxe3 StringMap #else Hash #end <T>):Void {
		
		for (key in source.keys ()) {
			
			if (!target.exists (key)) {
				
				target.set (key, source.get (key));
				
			}
			
		}
		
	}
	
	
}