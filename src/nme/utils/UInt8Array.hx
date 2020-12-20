package nme.utils;

#if (!flash)
@:nativeProperty
class UInt8Array extends ArrayBufferView implements ArrayAccess<Int> 
{
   static public inline var SBYTES_PER_ELEMENT = 1;

   public var BYTES_PER_ELEMENT(default, null):Int;
   public var length(default, null):Int;

   // Constrctor: ElementCount,
   //             Array , startElement, elementCount
   //             ArrayBuffer, startByte, elementCount
   public function new(?inBufferOrArray:Dynamic, inStart:Int = 0, ?inElements:Null<Int>)
   {
      BYTES_PER_ELEMENT = 1;

      if (#if (haxe_ver>="4.1") Std.isOfType #else Std.is #end(inBufferOrArray,Int))
      {
         super( length = Std.int(inBufferOrArray) );
      }
      else if (#if (haxe_ver>="4.1") Std.isOfType #else Std.is #end(inBufferOrArray,Array))
      {
         var ints:Array<Int> = inBufferOrArray;
         if (inElements != null)
            length = inElements;
         else
            length = ints.length - inStart;

         super(length);

         #if !cpp
         buffer.position = 0;
         #end

         for(i in 0...length)
         {
            #if cpp
            untyped __global__.__hxcpp_memory_set_byte(bytes,i, ints[i+inStart]);
            #else
            buffer.writeByte(ints[i + inStart]);
            #end
         }
      }
      else
      {
         super(inBufferOrArray, inStart, inElements);
         length = byteLength;
      }
   }

   public static function fromBytes(bytes:haxe.io.Bytes, byteOffset:Int=0, ?len:Int )
      return new UInt8Array(bytes, byteOffset, len);

   public function subarray(start:Int = 0, ?end:Int) : UInt8Array
   {
      if (end==null)
         end = length;
      return new UInt8Array(buffer, (start)+byteOffset, (end-start) );
   }

   @:keep
   inline public function __get(index:Int):Int { return getUInt8(index); }

   @:keep
   inline public function __set(index:Int, v:Int):Int { setUInt8(index, v); return v;  }
}

#end
