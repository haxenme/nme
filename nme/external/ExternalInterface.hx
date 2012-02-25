package nme.external;
#if (cpp || neko)


import nme.Loader;


class ExternalInterface
{	
	
	public static var available(nmeIsAvailable, null):Bool;
	public static var marshallExceptions:Bool;
	public static var objectID:String;
	
	private static var callbacks:Hash<Dynamic> = new Hash<Dynamic>();
	
	
	public static function addCallback(functionName:String, closure:Dynamic):Void
	{	
		if (!callbacks.exists (functionName))
		{
			nme_external_interface_add_callback(functionName, handler);
		}
		callbacks.set (functionName, closure);
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
	
	
	private static function handler (functionName:String, params:Array<String>):String {
		
		if (callbacks.exists (functionName)) {
			
			var callbackMethod = callbacks.get (functionName);
			return Reflect.callMethod (callbackMethod, callbackMethod, params);
			
		}
		
		return null;
		
	}
	
	
	public static function registerCallbacks():Void
	{
		nme_external_interface_register_callbacks();
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
	private static var nme_external_interface_register_callbacks = Loader.load("nme_external_interface_register_callbacks", 0);
	
}


#elseif js

import nme.Lib;

class ExternalInterface {
	static var mCallbacks:Hash<Dynamic>;
	public static inline var available : Bool = true;

	public static inline var objectID : String = Lib.canvas.id;
	public static function addCallback(functionName : String, closure : Dynamic) 
	{
		if (mCallbacks == null) mCallbacks = new Hash();
		mCallbacks.set(functionName, closure);
	}

	public static function call(functionName : String, ?p1 : Dynamic, ?p2 : Dynamic, ?p3 : Dynamic, ?p4 : Dynamic, ?p5 : Dynamic ) : Dynamic
	{
		if (!mCallbacks.exists(functionName)) return null;
		return Reflect.callMethod( null, mCallbacks.get(functionName), [p1, p2, p3, p4, p5] );
	}

	public static var marshallExceptions : Bool = false;
}

#else
typedef ExternalInterface = flash.external.ExternalInterface;
#end