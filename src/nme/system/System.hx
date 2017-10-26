package nme.system;

#if (!flash)

import nme.Lib;
import nme.Loader;
#if android
import nme.JNI;
#end

#if cpp
import cpp.vm.Gc;
#end

@:nativeProperty
class System 
{
   public static var deviceID(get_deviceID, null):String;
   public static var totalMemory(get_totalMemory, null):Int;
   public static var totalMemoryNumber(get_totalMemoryNumber, null):Float;
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
         //return untyped __js_run_gc();
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

   private static function get_totalMemoryNumber():Float 
   {
      return totalMemory;
   }

   public static function pauseForGCIfCollectionImminent(imminence:Float = 0.75):Void
   { 
      #if cpp
        var current = Gc.memInfo(Gc.MEM_INFO_CURRENT);
        var reserved =Gc.memInfo(Gc.MEM_INFO_RESERVED);
        if (current > reserved*imminence)
           Gc.run(true);
      #end
   }

   public static function systemName() : String
   {
      #if android
      return "android";
      #elseif iphone
      return "ios";
      #elseif js
      return "js";
      #else
      return Sys.systemName().toLowerCase();
      #end
   }

   public static function setClipboard(string:String):Void
   {
      var cb = new nme.desktop.Clipboard();
      cb.setData( nme.desktop.ClipboardFormats.TEXT_FORMAT, string);
   }

   private static function get_exeName():String
   {
      var func = Loader.load("nme_sys_get_exe_name", 0);
      return func();
   }

   public static function restart() : Void
   {
      #if android
      var restart = JNI.createStaticMethod("org/haxe/nme/GameActivity", "restartProcess", "()V");
      if (restart==null)
          throw "Could not find restart function";
      restart();
      #elseif jsprime
      // Sys.exit(0);
      #else
      Sys.exit(0);
      #end
   }

   public static function getLocalIpAddress() : String
   {
      #if android
      var func = JNI.createStaticMethod("org/haxe/nme/GameActivity", "getLocalIpAddress", "()Ljava/lang/String;");
      if (func==null)
          throw "Could not find getLocalIpAddress function";
      return func();
      #elseif iphone
      return nme_get_local_ip_address();
      #elseif jsprime
      // TODO
      return "localhost";
      #elseif winrt
      return "localhost";
      #else
      return sys.net.Host.localhost();
      #end
   }


   // Native Methods
   private static var nme_get_unique_device_identifier = Loader.load("nme_get_unique_device_identifier", 0);
   #if iphone
   private static var nme_get_local_ip_address = Loader.load("nme_get_local_ip_address", 0);
   #end
}

#else
typedef System = flash.system.System;
#end
