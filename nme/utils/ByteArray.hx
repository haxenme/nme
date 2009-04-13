package nme.utils;

import nme.geom.Rectangle;
import I32;

/**
* @author	Hugh Sanderson
* @author	Russell Weir
**/
class ByteArray extends haxe.io.Input, implements ArrayAccess<Int>
{
	private var mArray:Dynamic;
	public  var position:Int;
	public var endian(__getEndian,__setEndian) : String;

	public var length(get_length,null):Int;

	public function new(?inHandle:Dynamic)
	{
		if (inHandle==null)
			mArray = nme_create_byte_array();
		else
			mArray = inHandle;
		position = 0;
	}

	public function get_handle():Dynamic { return mArray; }

	public function get_length():Int
	{
		return nme_byte_array_length(mArray);
	}

	private function __get( pos:Int ) : Int
	{
		return nme_byte_array_get(mArray,pos);
	}

	private function __set(pos:Int,v:Int) : Void
	{
		nme_byte_array_set(mArray,pos,v);
	}

	static public function readFile(inString:String):ByteArray
	{
		var handle = nme_read_file(#if neko untyped inString.__s #else inString #end);
		return new ByteArray(handle);
	}

	public override function readByte():Int { return nme_byte_array_get(mArray,position++); }

	public function readInt() : Int32
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

	private function __getEndian() : String {
		return bigEndian ? Endian.BIG_ENDIAN : Endian.LITTLE_ENDIAN;
	}

	private function __setEndian(s:String) : String {
		bigEndian = (s == Endian.BIG_ENDIAN) ? true : false;
		return s;
	}



	static var nme_create_byte_array = nme.Loader.load("nme_create_byte_array",0);
	static var nme_byte_array_length = nme.Loader.load("nme_byte_array_length",1);
	static var nme_byte_array_get = nme.Loader.load("nme_byte_array_get",2);
	static var nme_byte_array_set = nme.Loader.load("nme_byte_array_set",3);
	static var nme_read_file = nme.Loader.load("nme_read_file",1);

}


