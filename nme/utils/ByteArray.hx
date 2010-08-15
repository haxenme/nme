package nme.utils;

import nme.geom.Rectangle;

/**
* @author	Hugh Sanderson
* @author	Russell Weir
**/


#if cpp
import haxe.io.BytesData;
typedef ByteBuffer = BytesData;
#else
typedef ByteBuffer = Dynamic;
#end

class ByteArray extends haxe.io.Input, implements ArrayAccess<Int>
{
	public  var position:Int;
	public var endian(nmeGetEndian,nmeSetEndian) : String;
	public var nmeData:ByteBuffer;

	public var length(nmeGetLength,null):Int;

	public function new(inLen:Int = 0)
	{
		#if cpp
		nmeData = new ByteBuffer();
		if (inLen>0) nmeData[inLen-1];
		#else
		nmeData = nme_byte_array_create(inLen);
		#end
		position = 0;
	}

	public function nmeGetData():Dynamic { return nmeData; }

	inline function nmeGetLength():Int
	{
	#if cpp
		return nmeData.length;
	#else
		return nme_byte_array_get_length(nmeData);
	#end
	}

   // Neko/cpp pseudo array accessors...
	inline private function __get( pos:Int ) : Int
	{
	#if cpp
		return untyped nmeData[pos];
	#else
		return nme_byte_array_get(nmeData,pos);
	#end
	}

	inline private function __set(pos:Int,v:Int) : Void
	{
	#if cpp
		untyped nmeData[pos] = pos;
	#else
		nme_byte_array_set(nmeData,pos,v);
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
	#if cpp
		return untyped nmeData[position++];
	#else
		return nme_byte_array_get(nmeData,position++);
	#end
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
	static var nme_byte_array_read_file = nme.Loader.load("nme_byte_array_read_file",1);
	static var nme_byte_array_get_length = nme.Loader.load("nme_byte_array_get_length",1);
	static var nme_byte_array_get = nme.Loader.load("nme_byte_array_get",2);
	static var nme_byte_array_set = nme.Loader.load("nme_byte_array_set",3);
}


