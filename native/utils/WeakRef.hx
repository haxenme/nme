package native.utils;


import native.Loader;


// This should actually be "possible WeakRef"
class WeakRef<T> {
	
	
	/** @private */ private var hardRef:T; // Allowing for the reference to be hard simplfies usage
	/** @private */ private var weakRef:Int;
	
	
	public function new (inObject:T, inMakeWeak:Bool = true) {
		
		if (inMakeWeak) {
			
			weakRef = nme_weak_ref_create (this, inObject);
			hardRef = null;
			
		} else {
			
			weakRef = -1;
			hardRef = inObject;
			
		}
		
	}
	
	
	public function get ():T {
		
		if (hardRef != null)
			return hardRef;
		
		if (weakRef < 0)
			return null;
		
		var result = nme_weak_ref_get (weakRef);
		if (result == null)
			weakRef = -1;
		
		return result;
		
	}
	
	
	public function toString ():String {
		
		if (hardRef == null)
			return "" + hardRef;
		
		return "WeakRef(" + weakRef + ")";
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	private static var nme_weak_ref_create = Loader.load ("nme_weak_ref_create", 2);
	private static var nme_weak_ref_get = Loader.load ("nme_weak_ref_get", 1);
	
	
}