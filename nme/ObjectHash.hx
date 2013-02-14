package nme;


#if flash
import flash.utils.TypedDictionary;
#end

#if haxe3
typedef IntHash<T> = haxe.ds.IntMap<T>;
#end


class ObjectHash <K, T> {
	
	
	#if flash
	/** @private */ private var dictionary:TypedDictionary <K, T>;
	#else
	/** @private */ private var hashKeys:IntHash <K>;
	/** @private */ private var hashValues:IntHash <T>;
	#end
	
	/** @private */ private static var nextObjectID:Int = 0;
	
	
	public function new() {
		
		#if flash
		
		dictionary = new TypedDictionary <K, T>();
		
		#else
		
		hashKeys = new IntHash <K>();
		hashValues = new IntHash <T>();
		
		#end
		
	}
	
	
	public inline function exists(key:K):Bool {
		
		#if flash
		
		return dictionary.exists(key);
		
		#else
		
		return hashValues.exists(getID(key));
		
		#end
		
	}
	
	
	public inline function get(key:K):T {
		
		#if flash
		
		return dictionary.get(key);
		
		#else
		
		return hashValues.get(getID(key));
		
		#end
		
	}
	
	
	/** @private */ private inline function getID(key:K):Int {
		
		#if cpp
		
		return untyped __global__.__hxcpp_obj_id(key);
		
		#elseif !flash
		
		if (untyped key.___id___ == null) {
			
			untyped key.___id___ = nextObjectID ++;
			
			if (nextObjectID == #if neko 0x3fffffff #else 0x7fffffff #end) {
				
				nextObjectID = 0;
				
			}
			
		}
		
		return untyped key.___id___;
		
		#else
		
		return 0;
		
		#end
		
	}
	
	
	public inline function iterator():Iterator <T> {
		
		#if flash
		
		var values:Array <T> = new Array <T>();
		
		for (key in dictionary.iterator()) {
			
			values.push(dictionary.get(key));
			
		}
		
		return values.iterator();
		
		#else
		
		return hashValues.iterator();
		
		#end
		
	}
	
	
	public inline function keys():Iterator <K> {
		
		#if flash
		
		return dictionary.iterator();
		
		#else
		
		return hashKeys.iterator();
		
		#end
		
	}
	
	
	public inline function remove(key:K):Void {
		
		#if flash
		
		dictionary.delete(key);
		
		#else
		
		var id = getID(key);
		
		hashKeys.remove(id);
		hashValues.remove(id);
		
		#end
		
	}
	
	
	public inline function set(key:K, value:T):Void {
		
		#if flash
		
		dictionary.set(key, value);
		
		#else
		
		var id = getID(key);
		
		hashKeys.set(id, key);
		hashValues.set(id, value);
		
		#end
		
	}
	
	
}
