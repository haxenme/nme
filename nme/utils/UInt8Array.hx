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
   public function new(inBufferOrArray:Dynamic, inStart:Int = 0, ?inElements:Null<Int>)
   {
      BYTES_PER_ELEMENT = 1;

      if (Std.is(inBufferOrArray,Int))
      {
         super( length = Std.int(inBufferOrArray) );
      }
      else if (Std.is(inBufferOrArray,Array))
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
            untyped __global__.__hxcpp_memory_set_byte(bytes,i, ints[i]);
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

   @:keep
   inline public function __get(index:Int):Int { return getUInt8(index); }

   @:keep
   inline public function __set(index:Int, v:Int):Void { setUInt8(index, v);  }
}

#end
