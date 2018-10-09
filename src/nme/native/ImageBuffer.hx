package nme.native;

import nme.native.Include;
import nme.bare.Surface;
import cpp.Pointer;
import cpp.ConstPointer;

@:include("nme/ImageBuffer.h")
@:native("nme::ImageBuffer")
@:structAccess
extern class ImageBuffer extends nme.native.Object
{
   public static inline function fromBitmapData(inBitmapData:Surface) : Pointer<ImageBuffer>
   {
      var object:Pointer<Object> = Object.fromHandle(inBitmapData.nmeHandle);
      if (object!=null)
         return object.value.asImageBuffer();
      return null;
   }

   public function GetFlags() : Int;
   public function SetFlags(inFlags:Int) : Void;
   public function Format() : Int;
   public function Version() : Int;
   public function OnChanged() : Void;

   public function Width() : Int;
   public function Height() : Int;
   public function GetStride() : Int;
   // These functions tecnically return RawPointers, which can cause issues if the
   //  compiler inlines too much code
   public function GetBase() : ConstPointer<cpp.UInt8>;
   public function Edit() : Pointer<cpp.UInt8>;
   public function EditRect(x:Int, y:Int, w:Int, h:Int) : Pointer<cpp.UInt8>;

   public function Row(inRow:Int) : cpp.RawPointer<cpp.UInt8>;

   public function Commit():Void;
}

