package nme.utils;

import nme.geom.Rectangle;

/**
* @author   Hugh Sanderson
* @author   Russell Weir
**/


class ByteArray extends haxe.io.Input, implements ArrayAccess<Int>
{
   public  var position:Int;
   public var endian(nmeGetEndian,nmeSetEndian) : String;
   public var nmeData:Dynamic;

   public var length(nmeGetLength,null):Int;

   public function new(inLen:Int = 0)
   {
      nmeData = nme_byte_array_create(inLen);
      position = 0;
   }

   public function nmeGetData():Dynamic { return nmeData; }

   public function asString() : String
   {
      return nme_byte_array_as_string(nmeData);
   }

   inline function nmeGetLength():Int
   {
      return nme_byte_array_get_length(nmeData);
   }

   // Neko/cpp pseudo array accessors...
   inline public function __get( pos:Int ) : Int
   {
      return nme_byte_array_get(nmeData,pos);
   }

   inline public function __set(pos:Int,v:Int) : Void
   {
      nme_byte_array_set(nmeData,pos,v);
   }

   public function getBytes() : haxe.io.Bytes
   {
		#if cpp
      var bytes = haxe.io.Bytes.alloc(length);
      nme_byte_array_get_bytes(nmeData,bytes.getData());
      return bytes;
      #else
		var str = asString();
      trace(str.length);
		return haxe.io.Bytes.ofString(str);
      #end
   }

   static public function readFile(inString:String):ByteArray
   {
      var handle = nme_byte_array_read_file(inString);
      var result = new ByteArray();
      result.nmeData = handle;
      return result;
   }

   // does the "work" for haxe.io.Input
   public override function readByte():Int
   {
      return nme_byte_array_get(nmeData,position++);
   }

#if neko
   public function readInt() : haxe.Int32
#else
   public function readInt() : Int
#end
   {
      return cast readInt32();
   }

   public inline function readShort() : Int {
      return readInt16();
   }

   public inline function readUnsignedByte() : Int {
      return readByte();
   }

   public function readUTFBytes(inLen:Int)
   {
      return readString(inLen);
   }

   private function nmeGetEndian() : String {
      return bigEndian ? Endian.BIG_ENDIAN : Endian.LITTLE_ENDIAN;
   }

   private function nmeSetEndian(s:String) : String {
      bigEndian = (s == Endian.BIG_ENDIAN);
      return s;
   }

   static var nme_byte_array_create = nme.Loader.load("nme_byte_array_create",1);
   static var nme_byte_array_as_string = nme.Loader.load("nme_byte_array_as_string",1);
   #if cpp
   static var nme_byte_array_get_bytes = nme.Loader.load("nme_byte_array_get_bytes",2);
   #end
   static var nme_byte_array_read_file = nme.Loader.load("nme_byte_array_read_file",1);
   static var nme_byte_array_get_length = nme.Loader.load("nme_byte_array_get_length",1);
   static var nme_byte_array_get = nme.Loader.load("nme_byte_array_get",2);
   static var nme_byte_array_set = nme.Loader.load("nme_byte_array_set",3);
}


