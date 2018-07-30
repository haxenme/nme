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
   public function new(?inBufferOrArray:Dynamic, inStart:Int = 0, ?inElements:Null<Int>)
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

   public static function fromBytes(bytes:haxe.io.Bytes, byteOffset:Int=0, ?len:Int )
      return new Float32Array(bytes, byteOffset, len);

   public function subarray(start:Int = 0, ?end:Int) : Float32Array
   {
      if (end==null)
         end = length;
      return new Float32Array(buffer, (start<<2)+byteOffset, (end-start) );
   }

   @:generic
   public function TSet<T>(array:Array<T>,offset)
   {
      #if !cpp
      buffer.position = offset<<2;
      #end
      for(i in 0...array.length)
        #if cpp
        untyped __global__.__hxcpp_memory_set_float(bytes,((i+offset) << 2), cast array[i]);
        #else
        buffer.writeFloat(cast array[i + offset]);
        #end
   }

   public function set(inBufferOrArray:Dynamic, offset:Int=0)
   {
      #if cpp
      if (Std.is(inBufferOrArray,Array))
      {
         var a:Array<Float> = inBufferOrArray;
         if (a!=null)
         {
             TSet(a,offset);
             return;
         }

         var a:Array<Int> = inBufferOrArray;
         if (a!=null)
         {
             TSet(a,offset);
             return;
         }

         var a:Array<cpp.Float32> = inBufferOrArray;
         if (a!=null)
         {
             TSet(a,offset);
             return;
         }

         var a:Array<cpp.UInt8> = inBufferOrArray;
         if (a!=null)
         {
             TSet(a,offset);
             return;
         }

         var a:Array<cpp.Int8> = inBufferOrArray;
         if (a!=null)
         {
             TSet(a,offset);
             return;
         }
     }
     else
     #end
     if (Std.is(inBufferOrArray,ArrayBufferView))
     {
        var a:ArrayBufferView = inBufferOrArray;
        var length = a.byteLength>>2;
        for(i in 0...length)
           setFloat32( (i+offset)<<2, a.getFloat32(i<<2) );
     }

     for(i in 0...inBufferOrArray.length)
         __set(i+offset, inBufferOrArray[i]);
   }

   @:keep
   inline public function __get(index:Int):Float { return getFloat32(index << 2); }

   @:keep
   inline public function __set(index:Int, v:Float):Float { setFloat32(index << 2, v); return v; }
}

#end
