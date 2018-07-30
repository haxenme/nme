package nme.utils;
#if (!flash)

#if cpp
import haxe.io.BytesData;
#end

@:nativeProperty
class ArrayBufferView implements IMemoryRange 
{
   public var buffer(default, null):ByteArray;
   public var byteOffset(default, null):Int;
   public var byteLength(default, null):Int;

   static var invalidDataIndex = "Invalid data index";

   #if cpp
   var bytes:BytesData;
   #end

   private function new(inLengthOrBuffer:Dynamic, inByteOffset:Int = 0, ?inLength:Int) 
   {
      if (Std.is(inLengthOrBuffer, Int)) 
      {
         byteLength = Std.int(inLengthOrBuffer);
         byteOffset = 0;
         buffer = new ArrayBuffer(Std.int(inLengthOrBuffer));

      }
      else 
      {
         if (Std.is(inLengthOrBuffer, haxe.io.Bytes)) 
            buffer = ByteArray.fromBytes(inLengthOrBuffer);
         else
            buffer = inLengthOrBuffer;

         if (buffer == null)
            buffer = new ArrayBuffer(0);
            //throw("Invalid input buffer");

         byteOffset = inByteOffset;

         if (byteOffset > buffer.length)
            throw("Invalid starting position");

         if (inLength == null) 
         {
            byteLength = buffer.length - inByteOffset;

         }
         else 
         {
            byteLength = inLength;

            if (byteLength + byteOffset > buffer.length)
               throw("Invalid buffer length");
         }
      }

      buffer.bigEndian = false;

      #if cpp
      bytes = buffer.getData();
      #end
   }

   public function toBytes() : haxe.io.Bytes
      return buffer;

   public function setData(byteData:ArrayBufferView, inOffset:Int)
   {
      var size = byteData.getLength();
      if (size+inOffset>byteLength)
         throw "Out of bounds";
      var targetOff = byteOffset + inOffset;
      buffer.blit(targetOff, byteData.getByteBuffer(), byteData.getStart(), size);
   }

   // IMemoryRange
   public function getByteBuffer():ByteArray { return buffer; }
   public function getStart():Int { return byteOffset; }
   public function getLength():Int { return byteLength; }

   inline public function getFloat32(bytePos:Int):Float 
   {
      #if debug
      if (bytePos - bytePos > 4) throw invalidDataIndex;
      #end

      #if cpp
      untyped return __global__.__hxcpp_memory_get_float(bytes, bytePos + byteOffset);
      #else
      buffer.position = bytePos + byteOffset;
      return buffer.readFloat();
      #end
   }

   inline public function setFloat32(bytePos:Int, v:Float):Void 
   {
      #if debug
      if (bytePos - bytePos > 4) throw invalidDataIndex;
      #end

      #if cpp
      untyped __global__.__hxcpp_memory_set_float(bytes, bytePos + byteOffset, v);
      #else
      buffer.position = bytePos + byteOffset;
      buffer.writeFloat(v);
      #end
   }

   inline public function getUInt8(bytePos:Int):Int 
   {
      #if debug
      if (bytePos - bytePos > 1) throw invalidDataIndex;
      #end

      #if cpp
      untyped return __global__.__hxcpp_memory_get_byte(bytes, bytePos + byteOffset);
      #else
      buffer.position = bytePos + byteOffset;
      return buffer.readByte();
      #end
   }

   inline public function setUInt8(bytePos:Int, v:Int):Void 
   {
      #if debug
      if (bytePos - bytePos > 1) throw invalidDataIndex;
      #end

      #if cpp
      untyped __global__.__hxcpp_memory_set_byte(bytes, bytePos + byteOffset, v);
      #else
      buffer.position = bytePos + byteOffset;
      buffer.writeByte(v);
      #end
   }

   inline public function getInt16(bytePos:Int):Int 
   {
      #if cpp
      untyped return __global__.__hxcpp_memory_get_i16(bytes, bytePos + byteOffset);
      #else
      buffer.position = bytePos + byteOffset;
      return buffer.readShort();
      #end
   }


   inline public function getUInt16(bytePos:Int):Int 
   {
      #if cpp
      untyped return __global__.__hxcpp_memory_get_ui16(bytes, bytePos + byteOffset);
      #else
      buffer.position = bytePos + byteOffset;
      return buffer.readUnsignedShort();
      #end
   }

   inline public function setInt16(bytePos:Int, v:Int):Void 
   {
      #if cpp
      untyped __global__.__hxcpp_memory_set_i16(bytes, bytePos + byteOffset, v);
      #else
      buffer.position = bytePos + byteOffset;
      buffer.writeShort(Std.int(v));
      #end
   }


   inline public function setUInt16(bytePos:Int, v:Int):Void 
   {
      #if cpp
      untyped __global__.__hxcpp_memory_set_ui16(bytes, bytePos + byteOffset, v);
      #else
      buffer.position = bytePos + byteOffset;
      buffer.writeShort(Std.int(v));
      #end
   }
   
   inline public function getInt32(bytePos:Int):Int 
   {
      #if cpp
      untyped return __global__.__hxcpp_memory_get_i32(bytes, bytePos + byteOffset);
      #else
      buffer.position = bytePos + byteOffset;
      return buffer.readInt();
      #end
   }

   inline public function setInt32(bytePos:Int, v:Int):Void 
   {
      #if cpp
      untyped __global__.__hxcpp_memory_set_i32(bytes, bytePos + byteOffset, v);
      #else
      buffer.position = bytePos + byteOffset;
      buffer.writeInt(Std.int(v));
      #end
   }
}

#end
