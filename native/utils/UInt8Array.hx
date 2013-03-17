package native.utils;

#if (cpp || neko)

class UInt8Array extends ArrayBufferView implements ArrayAccess<Int> 
{

   static public inline var SBYTES_PER_ELEMENT = 1;

   public var BYTES_PER_ELEMENT(default, null):Int;
   public var length(default, null):Int;

   // Constrctor: length, array, int[], ArrayBuffer + start + len
   public function new(inBufferOrArray:Dynamic, inStart:Int = 0, ?inLen:Null<Int>)
   {
      BYTES_PER_ELEMENT = 1;
      var ints:Array<Int> = inBufferOrArray;

      if (!Std.is(inBufferOrArray,ArrayBuffer) && ints != null)
      {
         if (inLen != null)
            length = inLen;
         else
            length = ints.length - inStart;

         super(length);

         #if !cpp
         buffer.position = 0;
         #end

         for(i in 0...length)
         {
            #if cpp
            untyped __global__.__hxcpp_memory_set_byte(bytes,i, ints[i]);
            #else
            buffer.writeByte(ints[i + inStart]);
            #end
         }
      }
      else
      {
         super(inBufferOrArray, inStart, inLen);
         length = byteLength;
      }
   }

   inline public function __get(index:Int):Int { return getUInt8(index); }
   inline public function __set(index:Int, v:Int):Void { setUInt8(index, v); }
}

#end
