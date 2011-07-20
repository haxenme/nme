package nme.utils;

// Ensure that the neko->haxe callbacks are initialized
import nme.errors.EOFError;

#if neko
import neko.Lib;
import neko.zip.Compress;
import neko.zip.Uncompress;
import neko.zip.Flush;
#else
import cpp.Lib;
import cpp.zip.Compress;
import cpp.zip.Uncompress;
import cpp.zip.Flush;
#end

class ByteArray extends haxe.io.Bytes, implements ArrayAccess<Int>, implements IDataInput
{
   public var position:Int;
   public var endian(nmeGetEndian,nmeSetEndian) : String;
   public var bytesAvailable(nmeGetBytesAvailable,null) : Int;
   public var bigEndian:Bool;

   #if neko
   var alloced:Int;
   #end

   public function new(inSize=0)
   {
      bigEndian = true;
      position = 0;
      if (inSize>=0)
      {
         #if neko
         alloced = inSize < 16 ? 16 : inSize;
         var bytes = untyped __dollar__smake(alloced);
         super(inSize,bytes);
         #else
         var data = new haxe.io.BytesData();
         if (inSize>0)
            untyped data[inSize-1] = 0;
         super(inSize,data);
         #end
      }
   }

   static public function fromBytes(inBytes:haxe.io.Bytes)
   {
      var result = new ByteArray(-1);
      result.b = inBytes.b;
      result.length = inBytes.length;
      #if neko
      result.alloced = result.length;
      #end
      return result;
   }


   public function setLength(inLength:Int):Void
   {
      if (inLength>0)
        ensureElem(inLength-1);
      length = inLength;
   }

   public function checkData(inLength:Int)
   {
      if (inLength+position>length)
         ThrowEOFi();
   }


   #if !no_nme_io
   static public function readFile(inString:String):ByteArray
   {
      return nme_byte_array_read_file(inString);
   }

   public function writeFile(inString:String):Void
   {
      nme_byte_array_overwrite_file(inString, this);
   }
   #end


   // Neko/cpp pseudo array accessors...
   // No bounds checking is done in the cpp case
   inline public function __get( pos:Int ) : Int
   {
      #if cpp
      return untyped b[pos];
      #else
      return get(pos);
      #end
   }

   // No bounds checking is done in the cpp case
   inline public function __set(pos:Int,v:Int) : Void
   {
      #if cpp
      untyped b[pos] = v;
      #else
      set(pos,v);
      #end
   }


   public function compress(algorithm:String="")
   {
      #if neko
      var src = alloced==length ? this : sub(0,length);
      #else
      var src = this;
      #end
      var result = Compress.run(src,8);
      b = result.b;
      length = result.length;
      position = length;
      #if neko
      alloced = length;
      #end
   }

   public function uncompress(algorithm:String="")
   {
      #if neko
      var src = alloced==length ? this : sub(0,length);
      #else
      var src = this;
      #end

      var result = Uncompress.run(src,null);
      b = result.b;
      length = result.length;
      position = 0;
      #if neko
      alloced = length;
      #end
   }

   function ThrowEOFi() : Int { throw new EOFError(); return 0; }


   // --- IDataInput -----------------------------------------------------------

   public function nmeGetBytesAvailable() : Int { return length - position; }

   public inline function readByte() : Int
   {
      return (position<length) ? __get(position++) : ThrowEOFi();
   }
   public inline function readBoolean() : Bool
   {
      return (position+1<length) ? __get(position++)!=0 : ThrowEOFi()!=0;
   }
   public function readBytes(outData:ByteArray,inOffset:Int=0,inLen:Int=0) : Void
   {
      if (inLen==0)
         inLen = length - position;
      if (position+inLen>length)
        ThrowEOFi();
      if (outData.length < inOffset+inLen)
        outData.ensureElem(inOffset+inLen-1);

     #if neko
     outData.blit(inOffset, this, position,inLen);
     #else
     var b1 = b;
     var b2 = outData.b;
     var p = position;
     for( i in 0...inLen )
         b2[inOffset+i] = b1[p+i];
     #end
     position += inLen;
   }

   public function readFloat() : Float
   {
      if (position+4>length)
        ThrowEOFi();
   
      #if neko
         var bytes = new haxe.io.Bytes(4,untyped __dollar__ssub(b,position,4));
      #elseif cpp
         var bytes = new haxe.io.Bytes(4,b.slice(position,position+4));
      #end

      position += 4;
      return _float_of_bytes(bytes.b,bigEndian);
   }

   public function readDouble() : Float
   {
      if (position+8>length)
        ThrowEOFi();

     #if neko
         var bytes = new haxe.io.Bytes(8,untyped __dollar__ssub(b,position,8));
      #elseif cpp
         var bytes = new haxe.io.Bytes(8,b.slice(position,position+8));
      #end

      position += 8;
      return _double_of_bytes(bytes.b,bigEndian);
   }


   public function readInt() : Int
   {
      var ch1 = readByte();
      var ch2 = readByte();
      var ch3 = readByte();
      var ch4 = readByte();
      return bigEndian ? (ch1<<24) | (ch2<<16) | (ch3<<8) | ch4 :
                         (ch4<<24) | (ch3<<16) | (ch2<<8) | ch1;
   }

   public function readShort() : Int
   {
      var ch1 = readByte();
      var ch2 = readByte();
      var val = bigEndian ? (ch1<<8) | ch2 : (ch2<<8) + ch1;
      return (val >= 0x8000 ) ? 65534 - val : val;
   }

   inline public function readUnsignedByte():Int { return readByte(); }
   public function readUnsignedInt():Int
   {
      var ch1 = readByte();
      var ch2 = readByte();
      var ch3 = readByte();
      var ch4 = readByte();
      return bigEndian ? (ch1<<24) | (ch2<<16) | (ch3<<8) | ch4 :
                         (ch4<<24) | (ch3<<16) | (ch2<<8) | ch1;
   }
   public function readUnsignedShort() : Int
   {
      var ch1 = readByte();
      var ch2 = readByte();
      return bigEndian ? (ch1<<8) | ch2 : (ch2<<8) + ch1;
   }
   public function readUTF():String
   {
      var len = readUnsignedShort();
      return readUTFBytes(len);
   }

   public function readUTFBytes(inLen : Int):String
   {
      if (position+inLen>length)
        ThrowEOFi();
      var p = position;
      position += inLen;
     
      #if neko
      return new String(untyped __dollar__ssub(b,p,inLen));
      #elseif cpp
      var result:String="";
      untyped __global__.__hxcpp_string_of_bytes(b,result,p,inLen);
      return result;
      #end
   }

   public function asString():String { return readUTFBytes(length); }

   public function nmeGetEndian() : String
   {
      return bigEndian ? Endian.BIG_ENDIAN : Endian.LITTLE_ENDIAN;
   }

   public function nmeSetEndian(s:String) : String
   {
      bigEndian = (s == Endian.BIG_ENDIAN);
      return s;
   }

   // --- IDataOutput -----------------------------------------------------------
   function ensureElem(inSize:Int)
   {
      #if neko
      if (alloced<inSize+1)
      {
         alloced = ( (inSize+1) * 3 ) >> 1;
         var new_b = untyped __dollar__smake(alloced);
         untyped __dollar__sblit(new_b,0,b,0,length);
         b = new_b;
      }
      #else
      untyped b.EnsureSize(inSize);
      #end
      if (length<inSize+1)
         length = inSize+1;
   }


   inline function push_uncheck(inByte:Int)
   {
      #if cpp
      untyped b.__unsafe_set(length++,inByte);
      #else
      untyped __dollar__sset(b,length++,inByte & 0xff);
      #end
   }

   #if cpp inline #end function push(inByte:Int)
   {
      #if cpp
      b[length++] = untyped inByte;
      #else
      ensureElem(length);
      untyped __dollar__sset(b,length++,inByte & 0xff);
      #end
   }
   

   public function writeBoolean(value:Bool)
   {
      push(value?1:0);
   }
   public function writeByte(value:Int)
   {
      push(value);
   }
   public function writeBytes(bytes:haxe.io.Bytes, inOffset:Int = 0, inLength:Int = 0)
   {
      if (inLength==0)
        inLength = bytes.length;
      ensureElem(length+inLength-1);
      var olen = length;
      length+=inLength;
      blit(olen,bytes,inOffset,inLength);
   }
   public function writeDouble(x:Float)
   {
		#if neko
		var bytes = new haxe.io.Bytes(8,_double_bytes(x,bigEndian));
		#elseif cpp
		var bytes = haxe.io.Bytes.ofData(_double_bytes(x,bigEndian));
		#end
      writeBytes(bytes);
   }
   public function writeFloat(x:Float)
   {
		#if neko
		var bytes = new haxe.io.Bytes(4,_float_bytes(x,bigEndian));
		#elseif cpp
		var bytes = haxe.io.Bytes.ofData(_float_bytes(x,bigEndian));
		#end
      writeBytes(bytes);
   }
   public function writeInt(value:Int)
   {
      ensureElem(length+3);
      if (bigEndian)
      {
          push_uncheck(value>>24);
          push_uncheck(value>>16);
          push_uncheck(value>>8);
          push_uncheck(value);
      }
      else
      {
          push_uncheck(value);
          push_uncheck(value>>8);
          push_uncheck(value>>16);
          push_uncheck(value>>24);
      }
   }
   // public function writeMultiByte(value:String, charSet:String)
   // public function writeObject(object:*)
   public function writeShort(value:Int)
   {
      ensureElem(length+2);
      if (bigEndian)
      {
          push_uncheck(value>>8);
          push_uncheck(value);
      }
      else
      {
          push_uncheck(value);
          push_uncheck(value>>8);
      }
   }
   public function writeUnsignedInt(value:Int)
   {
      writeInt(value);
   }
   public function writeUTF(s:String)
   {
		#if neko
		var bytes = new haxe.io.Bytes(s.length,untyped s.__s);
		#else
		var bytes = haxe.io.Bytes.ofString(s);
		#end
      writeShort(bytes.length);
      writeBytes(bytes);
   }
   public function writeUTFBytes(s:String)
   {
		#if neko
		var bytes = new haxe.io.Bytes(s.length,untyped s.__s);
		#else
		var bytes = haxe.io.Bytes.ofString(s);
		#end
      writeBytes(bytes);
   }

   static var _float_of_bytes = Lib.load("std","float_of_bytes",2);
   static var _double_of_bytes = Lib.load("std","double_of_bytes",2);
	static var _float_bytes = Lib.load("std","float_bytes",2);
	static var _double_bytes = Lib.load("std","double_bytes",2);

   #if !no_nme_io
   // Store these in statics there to avoid GC issues in nme
   static var factory:Dynamic;
   static var resize:Dynamic;
   static var slen:Dynamic;
   static var bytes:Dynamic;

   static function __init__()
   {
      factory = function(inLen:Int) { return new ByteArray(inLen); };
      resize  = function(inArray:ByteArray,inLen:Int) {
         if (inLen>0)
           inArray.ensureElem(inLen-1);
         inArray.length = inLen;
      };
      bytes  = function(inArray:ByteArray) { return inArray.b; }
      slen  = function(inArray:ByteArray) { return inArray==null ? 0 : inArray.length; }

      var init = nme.Loader.load("nme_byte_array_init",4);
      init(factory,slen,resize,bytes);
   }

   static var nme_byte_array_overwrite_file = nme.Loader.load("nme_byte_array_overwrite_file",2);
   static var nme_byte_array_read_file = nme.Loader.load("nme_byte_array_read_file",1);
   #end
}


