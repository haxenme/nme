#if flash


package nme.system;


@:native ("flash.system.System")
extern class System {
	@:require(flash10_1) static var freeMemory(default,null) : Float;
	static var ime(default,null) : IME;
	@:require(flash10_1) static var privateMemory(default,null) : Float;
	static var totalMemory(default,null) : UInt;
	@:require(flash10_1) static var totalMemoryNumber(default,null) : Float;
	static var useCodePage : Bool;
	static var vmVersion(default,null) : String;
	@:require(flash10_1) static function disposeXML(node : flash.xml.XML) : Void;
	static function exit(code : UInt) : Void;
	static function gc() : Void;
	@:require(flash10_1) static function nativeConstructionOnly(object : Dynamic) : Void;
	static function pause() : Void;
	static function resume() : Void;
	static function setClipboard(string : String) : Void;
}



#else


package nme.system;

class System
{
   public static var totalMemory(nmeGetTotalMemory,null): Int;
  public static var deviceID(nmeGetDeviceID, null):String;

  private static function nmeGetDeviceID():String
  {
    return nme_get_unique_device_identifier();
  }


	static function nmeGetTotalMemory() : Int
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

	static public function exit(?inCode:Int)
	{
	   nme.Lib.close();
	}

  static var nme_get_unique_device_identifier = nme.Loader.load("nme_get_unique_device_identifier",0);

}


#end