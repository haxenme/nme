package nme.system;
#if cpp || neko


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


#else
typedef System = flash.system.System;
#end