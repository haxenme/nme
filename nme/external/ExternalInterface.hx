package nme.external;
#if (cpp || neko)


import nme.Loader;


class ExternalInterface
{	
	
	public static var available(nmeIsAvailable, null):Bool;
	public static var marshallExceptions:Bool;
	public static var objectID:String;
	
	
	public static function addCallback(functionName:String, closure:Dynamic):Void
	{	
		nme_external_interface_add_callback(functionName, closure);	
	}
	
	
	public static function call(functionName:String, ?p1:Dynamic, ?p2:Dynamic, ?p3:Dynamic, ?p4:Dynamic, ?p5:Dynamic):Dynamic
	{	
		var params:Array<Dynamic> = new Array<Dynamic>();
		
		if (p1 != null)
		{	
			params.push(p1);
		}
		
		if (p2 != null)
		{
			params.push(p2);
		}
		
		if (p3 != null)
		{
			params.push(p3);
		}
		
		if (p4 != null)
		{	
			params.push(p4);
		}
		
		if (p5 != null)
		{	
			params.push(p5);	
		}
		
		return nme_external_interface_call(functionName, params);
	}
	
	
	
	// Getters & Setters
	
	
	
	private static function nmeIsAvailable():Bool
	{
		return nme_external_interface_available();
	}
	
	
	
	// Native Methods
	
	
	
	private static var nme_external_interface_add_callback = Loader.load("nme_external_interface_add_callback", 2);
	private static var nme_external_interface_available = Loader.load("nme_external_interface_available", 0);
	private static var nme_external_interface_call = Loader.load("nme_external_interface_call", 2);
	
}


#else
typedef ExternalInterface = flash.external.ExternalInterface;
#end