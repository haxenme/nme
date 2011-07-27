package nme.external;


import nme.Loader;


class ExternalInterface {
	
	
	public static var available (isAvailable, null):Bool;
	public static var marshallExceptions:Bool;
	public static var objectID:String;
	
	
	public static function addCallback (functionName:String, closure:Dynamic):Void {
		
		nme_external_interface_add_callback (functionName, closure);
		
	}
	
	
	public static function call (functionName:String, ?p1:Dynamic, ?p2:Dynamic, ?p3:Dynamic, ?p4:Dynamic, ?p5:Dynamic):Dynamic {
		
		var params:Array <Dynamic> = new Array <Dynamic> ();
		
		if (p1 != null) {
			
			params.push (p1);
			
		}
		
		if (p2 != null) {
			
			params.push (p2);
			
		}
		
		if (p3 != null) {
			
			params.push (p3);
			
		}
		
		if (p4 != null) {
			
			params.push (p4);
			
		}
		
		if (p5 != null) {
			
			params.push (p5);
			
		}
		
		return nme_external_interface_call (functionName, params);
		
	}
	
	
	private static function isAvailable ():Bool {
		
		return nme_external_interface_available ();
		
	}
	
	
	static var nme_external_interface_add_callback = Loader.load ("nme_external_interface_add_callback", 2);
	static var nme_external_interface_available = Loader.load ("nme_external_interface_available", 0);
	static var nme_external_interface_call = Loader.load ("nme_external_interface_call", 2);
	
	
}