package nme;

import nme.NativeHandle;

#if jsprime
import nme.PrimeLoader;
#end

class NativeResource
{
   public inline static var AUTO_CLEAR = 0x0001;
   public inline static var WRITE_ONLY = 0x0002;

   #if jsprime
   static function __init__() untyped
   {
      if (Module!=null)
      {
         Module.unrealize = unrealize;
         Module.realize = realize;
      }
   }

   @:keep
   static function unrealize(handle:NativeHandle, ptr:Int, len:Int, handleList:Dynamic)
   {
      var buffer = new js.html.ArrayBuffer(len);
      var bytes = new js.html.Uint8Array(buffer);
      var heap:js.html.Uint8Array = untyped Module.HEAP8;
      bytes.set(heap.subarray(ptr,ptr+len));
      untyped
      {
         handle.data = bytes;
         handle.handleList = handleList;
      }
   }

   @:keep
   static function realize(handle:NativeHandle) : Int
   {
      var bytes:js.html.Uint8Array = untyped handle.data;
      untyped handle.data = null;
      var len = bytes.length;

      // Get data byte size, allocate memory on Emscripten heap, and get pointer
      var ptr:Int = untyped Module._malloc(len);

      var heap = new js.html.Uint8Array(untyped Module.HEAPU8.buffer, ptr, len);
      heap.set(bytes);
      untyped handle.ptr = ptr;
      return len;
   }


   inline public static function disposeHandler(handler:NativeHandler) : Void
   {
      if (handler.nmeHandle!=null)
      {
         nme_native_resource_dispose(handler.nmeHandle);
         handler.nmeHandle = null;
      }
   }
   inline public static function lockHandler(handler:NativeHandler) : Void {
      nme_native_resource_lock(handler.nmeHandle);
   }
   inline public static function unlockHandler(handler:NativeHandler) : Void {
      nme_native_resource_unlock(handler.nmeHandle);
   }
   inline public static function setAutoClearHandler(handler:NativeHandler) : Void {
      var handle = handler.nmeHandle;
      if (handle!=null)
         handle.flags = handle.flags==null ? AUTO_CLEAR : handle.flags|AUTO_CLEAR;
   }
   inline public static function setWriteOnlyHandler(handler:NativeHandler) : Void {
      var handle = handler.nmeHandle;
      if (handle!=null)
         handle.flags = handle.flags==null ? WRITE_ONLY : handle.flags|WRITE_ONLY;
   }



   inline public static function dispose(handle:NativeHandle) : NativeHandle {
      if (handle!=null)
         nme_native_resource_dispose(handle);
      return null;
   }
   inline public static function lock(handle:NativeHandle) : Void {
      nme_native_resource_lock(handle);
   }
   inline public static function unlock(handle:NativeHandle) : Void {
      nme_native_resource_unlock(handle);
   }
   inline public static function setAutoClear(handle:NativeHandle) : Void {
      handle.flags = handle.flags==null ? AUTO_CLEAR : handle.flags|AUTO_CLEAR;
   }
   inline public static function setWriteOnly(handle:NativeHandle) : Void {
     handle.flags = handle.flags==null ? WRITE_ONLY : handle.flags|WRITE_ONLY;
   }
   inline public static function releaseTempRefs() : Void nme_native_resource_release_temps();

   static var nme_native_resource_dispose = PrimeLoader.load("nme_native_resource_dispose","ov");
   static var nme_native_resource_lock = PrimeLoader.load("nme_native_resource_lock","ov");
   static var nme_native_resource_unlock = PrimeLoader.load("nme_native_resource_unlock","ov");
   static var nme_native_resource_release_temps = PrimeLoader.load("nme_native_resource_release_temps","v");

   #else
   inline public static function disposeHandler(handler:NativeHandler) {
      handler.nmeHandle = null;
   }
   inline public static function setAutoClearHandler(handler:NativeHandler) : Void { }
   inline public static function setWriteOnlyHandler(handler:NativeHandler) : Void { }
   inline public static function lockHandler(handler:NativeHandler) : Void { }
   inline public static function unlockHandler(handler:NativeHandler) : Void { }

   inline public static function dispose(handle:NativeHandle) : NativeHandle return null;
   inline public static function setAutoClear(handle:NativeHandle) : Void { }
   inline public static function setWriteOnly(handle:NativeHandle) : Void { }
   inline public static function lock(handle:NativeHandle) : Void { }
   inline public static function unlock(handle:NativeHandle) : Void { }
   inline public static function releaseTempRefs() : Void { }

   #end
}


