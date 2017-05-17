package nme.native;

import nme.native.Include;
import cpp.Pointer;

@:include("nme/Object.h")
@:native("nme::Object")
@:structAccess
extern class Object
{
   public static inline var sKind = "nme::Object";

   public static inline function fromHandle(inHandle:Dynamic) : Pointer<Object>
   {
      return Pointer.fromHandle(inHandle,sKind);
   }

   public function getApiVersion() : Int;
   public function asImageBuffer() : Pointer<ImageBuffer>;
}

