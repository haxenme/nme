package nme.utils;
#if (!flash)

import haxe.io.Bytes;
import haxe.io.BytesData;
import nme.errors.EOFError; // Ensure that the neko->haxe callbacks are initialized
import nme.utils.CompressionAlgorithm;
import nme.PrimeLoader;
import nme.NativeResource;

#if neko
import neko.Lib;
import neko.zip.Compress;
import neko.zip.Uncompress;
import neko.zip.Flush;
#elseif cpp
import cpp.Lib;
import cpp.zip.Compress;
import cpp.zip.Uncompress;
import cpp.zip.Flush;
using cpp.NativeArray;
#end

#if jsprime
#if haxe4
   typedef JsUint8Array = js.lib.Uint8Array;
#else
   typedef JsUint8Array = js.html.Uint8Array;
#end
#end

typedef ByteArrayData = ByteArray;

@:cppFileCode('
namespace {
   float mangleFloat(float f) {
      char *c = (char *)&f;
      std::swap(c[0],c[3]);
      std::swap(c[1],c[2]);
      return f;
   }
   double mangleDouble(double d) {
      char *c = (char *)&d;
      std::swap(c[0],c[7]);
      std::swap(c[1],c[6]);
      std::swap(c[2],c[5]);
      std::swap(c[3],c[4]);
      return d;
   }

}
')
@:nativeProperty
class ByteArray extends Bytes implements ArrayAccess<Int> implements IDataInput implements IMemoryRange implements IDataOutput
{

   public var bigEndian:Bool;
   public var bytesAvailable(get, null):Int;
   public var endian(get, set):String;
   public var position:Int;
   public var byteLength(get,null):Int;
   public var __length(get,set):Int;

   #if jsprime
   // ptr is an offset into global memory allocated by c++ code
   // If the pointer is non-null then it is mapped into both JS and c++
   // If the buffer is allocated by JS, c++  must 'realize' the array to map it into memory
   //  and take ownership before it can access the data
   public var ptr:Null<Int>=null;
   public var flags:Int;
   #end

   #if (js||neko)
      private var alloced:Int;
   #end

   public function new(inSize:Int = 0,inWriteOnly=false)
   {
      bigEndian = true;
      position = 0;

      if (inSize<0)
        inSize = 0;

      #if (neko)
         alloced = inSize < 16 ? 16 : inSize;
         var bytes = untyped __dollar__smake(alloced);
         super(inSize, bytes);
      #elseif (js)
         alloced = inSize < 16 ? 16 : inSize;
         var bytes = new BytesData(alloced);
         super(bytes);
      #else
         var data = new BytesData();
         if (inSize > 0)
            untyped data[inSize - 1] = 0;
         super(inSize, data);
      #end

      #if jsprime
      if (inWriteOnly)
         NativeResource.setWriteOnly(this);
      onBufferChanged();
      #end
   }

   #if cpp
   #if (haxe_ver>=4)
      @:native("::mangleFloat")
      extern static function mangleFloat(f:Float):Float;
      @:native("::mangleDouble")
      extern static function mangleDouble(f:Float):Float;
   #else
      @:native("::mangleFloat")
      @:extern static function mangleFloat(f:Float):Float return 0;
      @:native("::mangleDouble")
      @:extern static function mangleDouble(f:Float):Float return 0;
   #end
   #end

   inline public function get___length() return length;
   inline public function set___length(inLength:Int) return setLength(inLength);
   inline public function __resize(inLength:Int) ensureElem(inLength-1,true);

    
   #if jsprime
   function onBufferChanged()
   {
      if (ptr>0)
      {
         var offset = ByteArray.nme_buffer_offset(ptr);
         b = new JsUint8Array(untyped Module.HEAP8.buffer, offset,alloced);
      }
      // Base class Bytes mapper will get reconstructed as needed ..
      data = null;
   }

   @:keep
   public function realize()
   {
      alloced = length;
      ptr = nme_buffer_create(length);
      if (length>0)
      {
         var offset = nme_buffer_offset(ptr);
         var heap:JsUint8Array = untyped Module.HEAP8;
         if (b.length<=length)
            heap.set(b,offset);
         else
            heap.set(b.subarray(0,length),offset);
      }
      b = null;
      onBufferChanged();
   }

   public function unrealize()
   {
      var f:Int = flags==null ? 0 : flags;
      if ( (f&NativeResource.AUTO_CLEAR) != 0)
      {
         ptr = null;
         alloced = 0;
         length = 0;
         data = null;
         b = null;
      }
      else
      {
         // As per js/_std/haxe/io/Bytes.hx
         alloced = length<16 ? 16 : length;
         var data = new BytesData(alloced);
         b = new JsUint8Array(data);
         untyped {
            b.bufferValue = data; // some impl does not return the same instance in .buffer
            data.hxBytes = this;
            data.bytes = this.b;
         }

         if (length>0 && (f&NativeResource.WRITE_ONLY) != 0)
         {
            var offset = nme_buffer_offset(ptr);
            var heap:JsUint8Array = untyped Module.HEAP8;
            b.set(heap.subarray(offset,offset+length));
         }
         ptr = null;
      }
      onBufferChanged();
   }


   static var nme_buffer_create = PrimeLoader.load("nme_buffer_create","ii");
   static var nme_buffer_offset = PrimeLoader.load("nme_buffer_offset","ii");
   static var nme_buffer_resize = PrimeLoader.load("nme_buffer_resize","iiv");
   static var nme_buffer_length = PrimeLoader.load("nme_buffer_length","ii");
   #else
   #end

   @:keep
   inline public function __get(pos:Int):Int 
   {
      // Neko/cpp pseudo array accessors...
      // No bounds checking is done in the cpp case
      #if cpp
      return untyped b[pos];
      #elseif jsprime
      return b[pos];
      #else
      return get(pos);
      #end
   }

   #if (!no_nme_io && (cpp||neko||jsprime))
   /** @private */ static function __init__() {
      var factory = function(inLen:Int) { return new ByteArray(inLen); };
      var resize = function(inArray:ByteArray, inLen:Int) 
      {
         if (inLen > 0)
            inArray.ensureElem(inLen - 1, true);
         inArray.length = inLen;

      };

      var bytes = function(inArray:ByteArray) { return inArray==null ? null :  inArray.b; }

      var slen = function(inArray:ByteArray) { return inArray == null ? 0 : inArray.length; }

      var init = PrimeLoader.load("nme_byte_array_init", "oooov");
      if (init!=null)
         init(factory, slen, resize, bytes);
   }
   #end

   @:keep
   inline public function __set(pos:Int, v:Int):Void 
   {
      // No bounds checking is done in the cpp case
      #if cpp
      untyped b[pos] = v;
      #elseif jsprime
      b[pos] = v;
      #else
      set(pos, v);
      #end
   }

   public function asString():String 
   {
      return readUTFBytes(length);
   }

   public function checkData(inLength:Int) 
   {
      if (inLength + position > length)
         ThrowEOFi();
   }

   public function clear() 
   {
      position = 0;
      length = 0;
   }

   #if (!js || jsprime)
   public function compress(algorithm:CompressionAlgorithm = null) 
   {
      #if (neko)
      var src = alloced == length ? this : sub(0, length);
      #else
      var src = this;
      #end

      var result:Bytes;

      if (algorithm == CompressionAlgorithm.LZMA) 
      {
         result = Bytes.ofData(nme_lzma_encode(src.getData()));
      }
      else 
      {
         var windowBits = switch(algorithm) 
         {
            case DEFLATE: -15;
            case GZIP: 31;
            default: 15;
         }

         #if jsprime
            alloced = length = nme_zip_encode(src);
            onBufferChanged();
         #elseif enable_deflate
            result = Compress.run(src, 8, windowBits);
         #elseif (cpp||neko)
            result = Compress.run(src, 8);
         #else
            // Dox/no output
            result = null;
         #end
      }

      #if !jsprime
         b = result.b;
         length = result.length;
         position = length;
         #if neko
         alloced = length;
         #end
      #end
   }

   public function deflate() 
   {
      compress(CompressionAlgorithm.DEFLATE);
   }
   #end

   public function setAllocSize(inSize:Int)
   {
      #if (js||neko)

         alloced = inSize;
         //if (alloced<16) alloced = 16;
         #if neko
            var new_b = untyped __dollar__smake(alloced);
            untyped __dollar__sblit(new_b, 0, b, 0, length);
            b = new_b;
         #else
            #if jsprime
               if (ptr>0)
               {
                  nme_buffer_resize(ptr,alloced);
               }
               else // fallthrough
            #end
            {
            var dest = new JsUint8Array(alloced);
            // TODO - something faster
            var copy = length<inSize ? length : inSize;
            for(i in 0...copy)
               dest[i] = b[i];
            b = dest;
            }
         #end

         #if jsprime
            onBufferChanged();
         #end

      #elseif (cpp || jsprime)
          b.setSize(inSize);
      #else
         // No-output/dox
      #end
   }

   public function setByteSize(inSize:Int)
   {
      setAllocSize(inSize);
      length = inSize;
   }

   private function ensureElem(inSize:Int, inUpdateLength:Bool)
   {
      var len = inSize + 1;

      #if (js||neko)
         if (alloced < len) 
            setAllocSize( ((((len+1) * 3) >> 1) + 3) & ~3 );
      #else
         if (b.length < len)
            untyped b.__SetSize(len);
      #end

      if (inUpdateLength && length < len)
         length = len;
   }

   static public function fromBytes(inBytes:Bytes) 
   {
      var result = new ByteArray( -1);
      result.nmeFromBytes(inBytes);
      return result;
   }

   public function getLength():Int { return length; }

   // IMemoryRange
   public function getByteBuffer():ByteArray { return this; }
   public function getStart():Int { return 0; }

   #if (!js || jsprime)
   public function inflate() 
   {
      uncompress(CompressionAlgorithm.DEFLATE);
   }
   #end
   
   private inline function nmeFromBytes(inBytes:Bytes):Void
   {
      b = inBytes.b;
      length = inBytes.length;
      
      #if (neko||js)
      alloced = length;
      #if jsprime
         ptr = null;
         onBufferChanged();
      #end
      #end
   }

   public inline function readBoolean():Bool 
   {
      return(position < length) ? __get(position++) != 0 : ThrowEOFi() != 0;
   }

   public inline function readByte():Int 
   {
      var val:Int = readUnsignedByte();
      return((val & 0x80) != 0) ?(val - 0x100) : val;
   }

   public function readBytes(outData:ByteArray, inOffset:Int = 0, inLen:Int = 0):Void 
   {
      if (inLen == 0)
         inLen = length - position;

      if (position + inLen > length)
         ThrowEOFi();

      if (outData.length < inOffset + inLen)
         outData.ensureElem(inOffset + inLen - 1, true);

      #if neko
         outData.blit(inOffset, this, position, inLen);
      #elseif jsprime
         var src = b.subarray(position,position+inLen);
         outData.b.set( src, inOffset);
      #else
         var b1 = b;
         var b2 = outData.b;
         var p = position;
         for(i in 0...inLen)
            b2[inOffset + i] = b1[p + i];
      #end

      position += inLen;
   }

   public function readDouble():Float 
   {
      if (position + 8 > length)
         ThrowEOFi();

      #if js
        var p = position;
        position += 8;
        return getDouble(p);
      #else

        #if neko
        var bytes = new Bytes(8, untyped __dollar__ssub(b, position, 8));
        position += 8;
        return _double_of_bytes(bytes.b, bigEndian);
        #elseif cpp
        var result:Float =  untyped __global__.__hxcpp_memory_get_double(b, position);
        position += 8;
        if (bigEndian) return mangleDouble(result);
        return result;
        #else
        // Dox/no output
        return 0;
        #end
      #end
   }

   #if !no_nme_io
   static public function readFile(inString:String):ByteArray 
   {
      return nme_byte_array_read_file(inString);
   }
   #end

   public function readFloat():Float 
   {
      if (position + 4 > length)
         ThrowEOFi();

      #if js
        var p = position;
        position += 4;
        return getFloat(p);
      #else
        #if neko
        var bytes = new Bytes(4, untyped __dollar__ssub(b, position, 4));
        position += 4;
        return _float_of_bytes(bytes.b, bigEndian);
        #elseif cpp
        var result:Float =  untyped __global__.__hxcpp_memory_get_float(b, position);
        position += 4;
        if (bigEndian) return mangleFloat(result);
        return result;
        #else
        // Dox/no-output
        return 0.0;
        #end

      #end
   }

   public function readInt():Int 
   {
      var ch1 = readUnsignedByte();
      var ch2 = readUnsignedByte();
      var ch3 = readUnsignedByte();
      var ch4 = readUnsignedByte();

      return bigEndian ?(ch1 << 24) |(ch2 << 16) |(ch3 << 8) | ch4 :(ch4 << 24) |(ch3 << 16) |(ch2 << 8) | ch1;
   }

   public inline function readMultiByte(inLen:Int, charSet:String):String 
   {
      // TODO - use code page
      return readUTFBytes(inLen);
   }

   public function readShort():Int 
   {
      var ch1 = readUnsignedByte();
      var ch2 = readUnsignedByte();

      var val = bigEndian ?((ch1 << 8) | ch2) :((ch2 << 8) | ch1);

      return((val & 0x8000) != 0) ?(val - 0x10000) : val;
   }

   inline public function readUnsignedByte():Int 
   {
      return(position < length) ? __get(position++) : ThrowEOFi();
   }

   public function readUnsignedInt():Int 
   {
      var ch1 = readUnsignedByte();
      var ch2 = readUnsignedByte();
      var ch3 = readUnsignedByte();
      var ch4 = readUnsignedByte();

      return bigEndian ?(ch1 << 24) |(ch2 << 16) |(ch3 << 8) | ch4 :(ch4 << 24) |(ch3 << 16) |(ch2 << 8) | ch1;
   }

   public function readUnsignedShort():Int 
   {
      var ch1 = readUnsignedByte();
      var ch2 = readUnsignedByte();

      return bigEndian ?(ch1 << 8) | ch2 :(ch2 << 8) + ch1;
   }

   public function readUTF():String 
   {
      var len = readUnsignedShort();
      return readUTFBytes(len);
   }

   public function readUTFBytes(inLen:Int):String 
   {
      if (position + inLen > length)
         ThrowEOFi();

      var p = position;
      position += inLen;

      #if neko
      return new String(untyped __dollar__ssub(b, p, inLen));
      #elseif cpp
      var result:String="";
      untyped __global__.__hxcpp_string_of_bytes(b, result, p, inLen);
      return result;
      #elseif js
      return getString(p,inLen);
      #else
      // No-output/dox
      return null;
      #end
   }

   public function setLength(inLength:Int): Int 
   {
      if (inLength > 0)
         ensureElem(inLength - 1, false);
      return length = inLength;
   }

   // ArrayBuffer interface
   public function slice(inBegin:Int, ?inEnd:Int):ByteArray 
   {
      var begin = inBegin;

      if (begin < 0) 
      {
         begin += length;
         if (begin < 0)
            begin = 0;
      }

      var end:Int = inEnd == null ? length : inEnd;

      if (end < 0) 
      {
         end += length;

         if (end < 0)
            end = 0;
      }

      if (begin >= end)
         return new ByteArray();

      var result = new ByteArray(end - begin);

      var opos = position;
      result.blit(0, this, begin, end - begin);

      return result;
   }

   /** @private */ private function ThrowEOFi():Int {
      throw new EOFError();
      return 0;
   }

   #if (!js || jsprime)
   public function uncompress(algorithm:CompressionAlgorithm = null):Void 
   {
      if (algorithm == null) algorithm = CompressionAlgorithm.GZIP;

      #if (neko)
      var src = alloced == length ? this : sub(0, length);
      #else
      var src = this;
      #end

      var result:Bytes;

      if (algorithm == CompressionAlgorithm.LZMA) 
      {
         result = Bytes.ofData(nme_lzma_decode(src.getData()));

      } else 
      {
         var windowBits = switch(algorithm) 
         {
            case DEFLATE: -15;
            case GZIP: 31;
            default: 15;
         }

         #if jsprime
            alloced = length = nme_zip_decode(src);
            b = null;
            onBufferChanged();
         #elseif enable_deflate
            result = Uncompress.run(src, null, windowBits);
         #elseif (neko||cpp)
            result = Uncompress.run(src, null);
         #else
            result = null;
         #end
      }

      #if !jsprime
         b = result.b;
         length = result.length;
         position = 0;
         #if (neko||js)
         alloced = length;
         #end
      #end
   }
   #end

   /** @private */ inline function write_uncheck(inByte:Int) {
      #if cpp
      untyped b.__unsafe_set(position++, inByte);
      #elseif neko
      untyped __dollar__sset(b, position++, inByte & 0xff);
      #else
      b[position++] = inByte;
      #end
   }

   public function writeBoolean(value:Bool) 
   {
      writeByte(value ? 1 : 0);
   }

   inline public function writeByte(value:Int) 
   {
      ensureElem(position, true);

      #if !neko
      b[position++] = untyped value;
      #else
      untyped __dollar__sset(b, position++, value & 0xff);
      #end
   }

   // This needs to support both
   //    writeBytes(bytes:ByteArray,...   for IDataOutput and
   //    writeBytes(bytes:Bytes,...       for haxe.io.Bytes and
   public function writeBytes(bytes:Dynamic, inOffset:Int = 0, inLength:Int = 0) 
   {
      writeHaxeBytes( bytes, inOffset, inLength );
   }

   public function writeHaxeBytes(bytes:Bytes, inOffset:Int, inLength:Int) 
   {
      if (inLength == 0) inLength = bytes.length - inOffset;
      ensureElem(position + inLength - 1, true);
      var opos = position;
      position += inLength;
      blit(opos, bytes, inOffset, inLength);
   }


   public function writeDouble(x:Float) 
   {
      var end = position + 8;
      ensureElem(end - 1, true);

      #if cpp
      // TODO - mangle double on all platforms too?
      if (bigEndian) x = mangleDouble(x);
      #end
      setDouble(position,x);
      position += 8;
   }

   #if !no_nme_io
   public function writeFile(inString:String):Void 
   {
      nme_byte_array_overwrite_file(inString, this);
   }
   #end

   public function writeFloat(x:Float) 
   {
      var end = position + 4;
      ensureElem(end - 1, true);
      #if cpp
      // TODO - mangle floats on neko too?
      if (bigEndian) x = mangleFloat(x);
      #end
      setFloat(position,x);
      position += 4;
   }

   public function writeInt(value:Int) 
   {
      ensureElem(position + 3, true);

      if (bigEndian) 
      {
         write_uncheck(value >> 24);
         write_uncheck(value >> 16);
         write_uncheck(value >> 8);
         write_uncheck(value);

      }
      else 
      {
         write_uncheck(value);
         write_uncheck(value >> 8);
         write_uncheck(value >> 16);
         write_uncheck(value >> 24);
      }
   }

   // public function writeMultiByte(value:String, charSet:String)
   // public function writeObject(object:*)
   public function writeShort(value:Int) 
   {
      ensureElem(position + 1, true);

      if (bigEndian) 
      {
         write_uncheck(value >> 8);
         write_uncheck(value);

      } else 
      {
         write_uncheck(value);
         write_uncheck(value >> 8);
      }
   }

   public function writeUnsignedInt(value:Int) 
   {
      writeInt(value);
   }

   public function writeUTF(s:String) 
   {
      #if neko
      var bytes = new Bytes(s.length, untyped s.__s);
      #else
      var bytes = Bytes.ofString(s);
      #end

      writeShort(bytes.length);
      writeHaxeBytes(bytes,0,0);
   }

   public function writeUTFBytes(s:String) 
   {
      #if neko
      var bytes = new Bytes(s.length, untyped s.__s);
      #else
      var bytes:haxe.io.Bytes = Bytes.ofString(s);
      #end

      writeHaxeBytes(bytes,0,0);
   }

   // Getters & Setters
   private function get_bytesAvailable():Int { return length - position; }
   private function get_byteLength():Int { return length; }
   private function get_endian():String { return bigEndian ? Endian.BIG_ENDIAN : Endian.LITTLE_ENDIAN; }
   private function set_endian(s:String):String { bigEndian =(s == Endian.BIG_ENDIAN); return s; }

   // Native Methods
   #if neko
   /** @private */ private static var _double_of_bytes = Lib.load("std", "double_of_bytes", 2);
   /** @private */ private static var _float_of_bytes = Lib.load("std", "float_of_bytes", 2);
   #end

   #if !no_nme_io
   private static var nme_byte_array_overwrite_file = nme.Loader.load("nme_byte_array_overwrite_file", 2);
   private static var nme_byte_array_read_file = nme.Loader.load("nme_byte_array_read_file", 1);
   #end
   private static var nme_lzma_encode = PrimeLoader.load("nme_lzma_encode", "oo");
   private static var nme_lzma_decode = PrimeLoader.load("nme_lzma_decode", "oo");
   #if jsprime
   private static var nme_zip_encode = PrimeLoader.load("nme_zip_encode", "oi");
   private static var nme_zip_decode = PrimeLoader.load("nme_zip_decode", "oi");
   #end
}

#else
typedef ByteArray = flash.utils.ByteArray;
#end
