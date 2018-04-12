package nme.utils;
#if (!flash)

import nme.geom.Matrix3D;

@:nativeProperty
class Float32Array extends ArrayBufferView implements ArrayAccess<Float> 
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
         length = Std.int(inBufferOrArray);
         super( length*BYTES_PER_ELEMENT );
      }
      else if (Std.is(inBufferOrArray,Array))
      {
         var floats:Array<Float> = inBufferOrArray;
         if (inElements != null)
            length = inElements;
         else
            length = floats.length - inStart;

         // 4 bytes per element -> shift it by two bits to get the lenght in bytes
         super(length << 2);

         #if !cpp
         buffer.position = 0;
         #end

         for(i in 0...length)
         {
            #if cpp
            untyped __global__.__hxcpp_memory_set_float(bytes,(i << 2), floats[i]);
            #else
            buffer.writeFloat(floats[i + inStart]);
            #end
         }
      }
      else
      {
         super(inBufferOrArray, inStart, inElements!=null ? inElements*4 : null);
         if ((byteLength & 0x03) > 0)
            throw("Invalid array size");
         length = byteLength >> 2;
         if ((length << 2) !=(byteLength))
            throw "Invalid length multiple";
      }
   }

   public static function fromMatrix(inMatrix:Matrix3D)
   {
      return new Float32Array(inMatrix.rawData);
   }

   @:keep
   inline public function __get(index:Int):Float { return getFloat32(index << 2); }

   @:keep
   inline public function __set(index:Int, v:Float):Float { setFloat32(index << 2, v); return v; }
}

#end
