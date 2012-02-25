package nme.system;
#if (cpp || neko)


import nme.Loader;


class System
{
	
	public static var deviceID(nmeGetDeviceID, null):String;
	public static var totalMemory(nmeGetTotalMemory, null):Int;
	
	
	static public function exit(?inCode:Int)
	{
		nme.Lib.close();
	}
	
	
	static public function gc()
	{
		#if neko
			return neko.vm.Gc.run(true);
		#elseif cpp
			return cpp.vm.Gc.run(true);
		#elseif js
			return untyped __js_run_gc();
		#else
			#error "System not supported on this target"
		#end
	}
	
	
	
	// Getters & Setters
	
	

	private static function nmeGetDeviceID():String { return nme_get_unique_device_identifier(); }
	
	
	private static function nmeGetTotalMemory():Int
	{
		#if neko
			return neko.vm.Gc.stats().heap;
		#elseif cpp
			return untyped __global__.__hxcpp_gc_used_bytes();
		#elseif js
			return untyped __js_get_heap_memory();
		#else
			#error "System not supported on this target"
		#end
	}
	
	
	
	// Native Methods
	
	
	
	private static var nme_get_unique_device_identifier = Loader.load("nme_get_unique_device_identifier", 0);
	
}


#elseif js

class System
{

	public static var vmVersion(getVersion,null) : String;

	public static function getVersion()
	{
		return "Jeash - tip";
	}

	public static var totalMemory(GetMemory,null) : Int;

	public static var useCodePage : Bool = false;

	public static function exit( code : Int ) : Void 
	{
		throw "System.close not implemented in Jeash";
	}
	public static function gc() : Void { }
	public static function pause() : Void
	{
		throw "System.pause not implemented in Jeash";
	}
	public static function resume() : Void
	{
		throw "System.resume not implemented in Jeash";
	}
	public static function setClipboard( string : String ) : Void
	{
		throw "System.setClipboard not implemented in Jeash";
	}

	static function GetMemory() : Int
	{
		return 0;
	}
}

#else
typedef System = flash.system.System;
#end