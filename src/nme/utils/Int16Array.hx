package nme.utils;

#if (!flash)

@:nativeProperty
class Int16Array extends ArrayBufferView #if !haxe3 , #end implements ArrayAccess<Int> 
{
   static public inline var SBYTES_PER_ELEMENT = 2;

   public var BYTES_PER_ELEMENT(default, null):Int;
   public var length(default, null):Int;

   // Constrctor: ElementCount,
   //             Array , startElement, elementCount
   //             ArrayBuffer, startByte, elementCount
   public function new(inBufferOrArray:Dynamic, inStart:Int = 0, ?inElements:Null<Int>) 
   {
      BYTES_PER_ELEMENT = 2;

      if (Std.is(inBufferOrArray,Int))
      {
         super( (length=Std.int(inBufferOrArray)) << 1 );
      }
      else if (Std.is(inBufferOrArray,Array))
      {
         var ints:Array<Int> = inBufferOrArray;
         if (inElements != null)
            length = inElements;
         else
            length = ints.length - inStart;

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
         super(inBufferOrArray, inStart, inElements!=null ? inElements*2 : null);

         if ((byteLength & 0x01) > 0)
            throw("Invalid array size");

         length = byteLength >> 1;
         if ((length << 1) !=(byteLength))
            throw "Invalid length multiple";
      }
   }

   public function subarray(start:Int = 0, ?end:Int) : Int16Array
   {
      if (end==null)
         end = length;
      return new Int16Array(buffer, (start<<1)+byteOffset, (end-start) );
   }

   @:keep
   inline public function __get(index:Int):Int { return getInt16(index << 1); }

   @:keep
   inline public function __set(index:Int, v:Int):Int { setInt16(index << 1, v); return v; }
}

#end
