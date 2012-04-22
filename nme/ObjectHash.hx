package nme;


#if flash
import flash.utils.TypedDictionary;
#end


class ObjectHash <T> {
	
	
	#if flash
	
	/** @private */ private var dictionary:TypedDictionary <Dynamic, T>;
	
	#else
	
	/** @private */ private var hash:IntHash <T>;
	
	#end
	
	/** @private */ private static var nextObjectID:Int = 0;
	
	
	public function new () {
		
		#if flash
		
		dictionary = new TypedDictionary <Dynamic, T> ();
		
		#else
		
		hash = new IntHash <T> ();
		
		#end
		
	}
	
	
	public inline function exists (key:Dynamic):Bool {
		
		#if flash
		
		return dictionary.exists (key);
		
		#else
		
		return hash.exists (getID (key));
		
		#end
		
	}
	
	
	public inline function get (key:Dynamic):T {
		
		#if flash
		
		return dictionary.get (key);
		
		#else
		
		return hash.get (getID (key));
		
		#end
		
	}
	
	
	/** @private */ private inline function getID (key:Dynamic):Int {
		
		#if cpp
		
		return untyped __global__.__hxcpp_obj_id (key);
		
		#else
		
		if (key.___id___ == null) {
			
			key.___id___ = nextObjectID ++;
			
			if (nextObjectID == #if neko 0x3fffffff #else 0x7fffffff #end) {
				
				nextObjectID = 0;
				
			}
			
		}
		
		return key.___id___;
		
		#else
		
		return 0;
		
		#end
		
	}
	
	
	public inline function iterator ():Iterator <T> {
		
		#if flash
		
		var values:Array <T> = new Array <T> ();
		
		for (key in dictionary.iterator ()) {
			
			values.push (dictionary.get (key));
			
		}
		
		return values.iterator ();
		
		#else
		
		return hash.iterator ();
		
		#end
		
	}
	
	
	/*public inline function keys ():Iterator <T> {
		
		#if flash
		
		return dictionary.iterator ();
		
		#else
		
		// Need to return the object, not the ID
		
		//return hash.keys ();
		
		#end
		
	}*/
	
	
	public inline function remove (key:Dynamic):Void {
		
		#if flash
		
		dictionary.delete (key);
		
		#else
		
		hash.remove (getID (key));
		
		#end
		
	}
	
	
	public inline function set (key:Dynamic, value:T):Void {
		
		#if flash
		
		dictionary.set (key, value);
		
		#else
		
		hash.set (getID (key), value);
		
		#end
		
	}
	
	
}