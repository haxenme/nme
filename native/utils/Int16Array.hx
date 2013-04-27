package native.utils;

#if (cpp || neko)

class Int16Array extends ArrayBufferView #if !haxe3 , #end implements ArrayAccess<Int> 
{
   static public inline var SBYTES_PER_ELEMENT = 2;

   public var BYTES_PER_ELEMENT(default, null):Int;
   public var length(default, null):Int;

   // Constrctor: length, array, float[], ArrayBuffer + start + len
   public function new(inBufferOrArray:Dynamic, inStart:Int = 0, ?inLen:Null<Int>) 
   {
      BYTES_PER_ELEMENT = 2;
      var ints:Array<Int> = inBufferOrArray;

      if (!Std.is(inBufferOrArray,ArrayBuffer) && ints != null) 
      {
            if (inLen != null)
            {
                length = inLen;
            }else
            {
                length = ints.length - inStart;
            }

            // 2 bytes per element -> shift it by one bits to get the lenght in bytes
         super(length << 1);

         #if !cpp
         buffer.position = 0;
         #end

         for(i in 0...length) 
         {
            #if cpp
            untyped __global__.__hxcpp_memory_set_i16(bytes,(i << 1), ints[i]);
            #else
            buffer.writeShort(ints[i + inStart]);
            #end
         }

      } else 
      {
         super(inBufferOrArray, inStart, inLen);

         if ((byteLength & 0x01) > 0)
            throw("Invalid array size");

         length = byteLength >> 1;
         if ((length << 1) !=(byteLength))
            throw "Invalid length multiple";
      }
   }

   inline public function __get(index:Int):Int { return getInt16(index << 1); }
   inline public function __set(index:Int, v:Int):Void { setInt16(index << 1, v); }
}

#end
