package browser.external;
#if js


class ExternalInterface {
	
	
	public static inline var available:Bool = true;
	public static var marshallExceptions:Bool = false;
	
	private static var mCallbacks:Map<String, Dynamic>;
	
	
	public static function addCallback(functionName:String, closure:Dynamic):Void {
		
		if (mCallbacks == null) mCallbacks = new Map <String, Dynamic>();
		mCallbacks.set(functionName, closure);
		
	}
	
	
	public static function call(functionName:String, ?p1:Dynamic, ?p2:Dynamic, ?p3:Dynamic, ?p4:Dynamic, ?p5:Dynamic):Dynamic {
		
		if (!mCallbacks.exists(functionName)) return null;
		return Reflect.callMethod(null, mCallbacks.get(functionName), [ p1, p2, p3, p4, p5 ]);
		
	}
	
	
}


#end