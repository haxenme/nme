package nme.system;

class System
{
   public static var totalMemory(nmeGetTotalMemory,null): Int;


	static function nmeGetTotalMemory() : Int
	{
	#if neko
	   return neko.vm.Gc.stats().heap;
	#elseif cpp
	   return untyped __global__.__hxcpp_gc_used_bytes();
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
	#else
	   #error "System not supported on this target"
	#end
	}

	static public function exit()
	{
	   nme.Lib.close();
	}
}
