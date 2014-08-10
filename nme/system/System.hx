package nme.system;
#if (cpp || neko)

import nme.Lib;
import nme.Loader;

class System 
{
   public static var deviceID(get_deviceID, null):String;
   public static var totalMemory(get_totalMemory, null):Int;
   public static var exeName(get_exeName, null):String;

   static public function exit(?inCode:Int) 
   {
      Lib.close();
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
   private static function get_deviceID():String { return nme_get_unique_device_identifier(); }

   private static function get_totalMemory():Int 
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

   public static function systemName() : String
   {
      #if android
      return "android";
      #elseif iphone
      return "ios";
      #elsif "js"
      return "js";
      #else
      return Sys.systemName().toLowerCase();
      #end
   }

   private static function get_exeName():String
   {
      var func = Loader.load("nme_sys_get_exe_name", 0);
      return func();
   }

   // Native Methods
   private static var nme_get_unique_device_identifier = Loader.load("nme_get_unique_device_identifier", 0);
}

#else
typedef System = flash.system.System;
#end
