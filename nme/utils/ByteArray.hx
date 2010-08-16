package nme.utils;

import nme.geom.Rectangle;

/**
* @author	Hugh Sanderson
* @author	Russell Weir
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
	}

	public function nmeGetData():Dynamic { return nmeData; }

	inline function nmeGetLength():Int
	{
		return nme_byte_array_get_length(nmeData);
	}

   // Neko/cpp pseudo array accessors...
	inline private function __get( pos:Int ) : Int
	{
		return nme_byte_array_get(nmeData,pos);
	}

	inline private function __set(pos:Int,v:Int) : Void
	{
		nme_byte_array_set(nmeData,pos,v);
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
	static var nme_byte_array_read_file = nme.Loader.load("nme_byte_array_read_file",1);
	static var nme_byte_array_get_length = nme.Loader.load("nme_byte_array_get_length",1);
	static var nme_byte_array_get = nme.Loader.load("nme_byte_array_get",2);
	static var nme_byte_array_set = nme.Loader.load("nme_byte_array_set",3);
}


