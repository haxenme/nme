package nme.utils;

import nme.geom.Rectangle;

/**
* @author	Hugh Sanderson
* @author	Russell Weir
**/
class ByteArray extends haxe.io.Input, implements ArrayAccess<Int>
{
	private var nmeData:haxe.io.Bytes;
	public  var position:Int;
	public var endian(nmeGetEndian,nmeSetEndian) : String;

	public var length(nmeGetLength,null):Int;

	public function new(?inBytes:haxe.io.Bytes)
	{
		if (inBytes==null)
			nmeData = haxe.io.Bytes.alloc(0);
		else
			nmeData = inBytes;
		position = 0;
	}

	public function nmeGetData():Dynamic { return nmeData; }

	function nmeGetLength():Int
	{
		return nmeData.length;
	}

   // Neko/cpp pseudo array accessors...
	private function __get( pos:Int ) : Int
	{
		return nmeData.get(pos);
	}

	private function __set(pos:Int,v:Int) : Void
	{
		return nmeData.set(pos,v);
	}

/*
	static public function readFile(inString:String):ByteArray
	{
		var handle = nme_byte_array_read_file(inString);
		return new ByteArray(handle);
	}
*/

   // does the "work" for haxe.io.Input
	public override function readByte():Int { return nmeData.get(position++); }

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

}


