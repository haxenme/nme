package nme.utils;
#if (cpp || neko)

@:arrayAccess
class Int32Array extends ArrayBufferView #if !haxe3 , #end implements ArrayAccess<Int> 
{
   static public inline var SBYTES_PER_ELEMENT = 4;

   public var BYTES_PER_ELEMENT(default, null):Int;
   public var length(default, null):Int;

   // Constrctor: ElementCount,
   //             Array , startElement, elementCount
   //             ArrayBuffer, startByte, elementCount
   public function new(inBufferOrArray:Dynamic, inStart:Int = 0, ?inElements:Null<Int>) 
   {
      BYTES_PER_ELEMENT = 4;

      if (Std.is(inBufferOrArray,Int))
      {
         super( Std.int(inBufferOrArray)<<2  );
      }
      else if (Std.is(inBufferOrArray,Array))
      {
         var ints:Array<Int> = inBufferOrArray;
         if (inElements != null)
            length = inElements;
         else
            length = ints.length - inStart;

            // 4 bytes per element -> shift it by two bits to get the length in bytes
         super(length << 2);

         #if !cpp
         buffer.position = 0;
         #end

         for(i in 0...length) 
         {
            #if cpp
            untyped __global__.__hxcpp_memory_set_i32(bytes,(i << 2), ints[i]);
            #else
            buffer.writeInt(ints[i + inStart]);
            #end
         }

      } else 
      {
         super(inBufferOrArray, inStart, inElements!=null ? inElements*4 : null);

         if ((byteLength & 0x03) > 0)
            throw("Invalid array size");

         length = byteLength >> 2;
         if ((length << 2) !=(byteLength))
            throw "Invalid length multiple";
      }
   }

   @:keep
   inline public function __get(index:Int):Int { return getInt32(index << 2); }

   @:keep
   inline public function __set(index:Int, v:Int):Void { setInt32(index << 2, v); }
}

#end
