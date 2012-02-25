package nme.utils;
#if (cpp || neko)


import haxe.io.Bytes;
import haxe.io.BytesData;
import nme.errors.EOFError; // Ensure that the neko->haxe callbacks are initialized
import nme.Loader;

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


class ByteArray extends Bytes, implements ArrayAccess<Int>, implements IDataInput
{
	
	public var bigEndian:Bool;
	public var bytesAvailable(nmeGetBytesAvailable, null):Int;
	public var endian(nmeGetEndian, nmeSetEndian):String;
	public var position:Int;
	
	#if !no_nme_io
	// Store these in statics there to avoid GC issues in nme
	private static var bytes:Dynamic;
	private static var factory:Dynamic;
	private static var resize:Dynamic;
	private static var slen:Dynamic;
	#end

	#if neko
	private var alloced:Int;
	#end
	
	
	public function new(inSize = 0)
	{
		bigEndian = true;
		position = 0;
		if (inSize >= 0)
		{
			#if neko
			alloced = inSize < 16 ? 16 : inSize;
			var bytes = untyped __dollar__smake(alloced);
			super(inSize, bytes);
			#else
			var data = new BytesData();
			if (inSize > 0)
				untyped data[inSize - 1] = 0;
			super(inSize, data);
			#end
		}
	}
	
	
	inline public function __get(pos:Int):Int
	{
		// Neko/cpp pseudo array accessors...
		// No bounds checking is done in the cpp case
		#if cpp
		return untyped b[pos];
		#else
		return get(pos);
		#end
	}
	
	
	#if !no_nme_io
	static function __init__()
	{
		factory = function(inLen:Int) { return new ByteArray(inLen); };
		resize  = function(inArray:ByteArray,inLen:Int) {
			if (inLen > 0)
				inArray.ensureElem(inLen - 1, true);
			inArray.length = inLen;
		};
		bytes = function(inArray:ByteArray) { return inArray==null ? null :  inArray.b; }
		slen = function(inArray:ByteArray) { return inArray == null ? 0 : inArray.length; }
		
		var init = Loader.load("nme_byte_array_init", 4);
		init(factory, slen, resize, bytes);
	}
	#end
	
	
	inline public function __set(pos:Int, v:Int):Void
	{
		// No bounds checking is done in the cpp case
		#if cpp
		untyped b[pos] = v;
		#else
		set(pos, v);
		#end
	}
	
	
	public function asString():String {
		
		return readUTFBytes(length);
		
	}
	
	
	public function checkData(inLength:Int)
	{
		if (inLength + position > length)
			ThrowEOFi();
	}
	
	
	public function compress(algorithm:String = "")
	{
		#if neko
		var src = alloced == length ? this : sub(0, length);
		#else
		var src = this;
		#end
		var result = Compress.run(src, 8);
		b = result.b;
		length = result.length;
		position = length;
		#if neko
		alloced = length;
		#end
	}
	
	
	private function ensureElem(inSize:Int, inUpdateLenght:Bool)
	{
		var len = inSize + 1;
		#if neko
		if (alloced < len)
		{
			alloced = ((len+1) * 3) >> 1;
			var new_b = untyped __dollar__smake(alloced);
			untyped __dollar__sblit(new_b, 0, b, 0, length);
			b = new_b;
		}
		#else
		if (b.length < len)
			untyped b.__SetSize(len);
		#end
		if (inUpdateLenght && length < len)
			length = len;
	}
	
	
	static public function fromBytes(inBytes:Bytes)
	{
		var result = new ByteArray (-1);
		result.b = inBytes.b;
		result.length = inBytes.length;
		#if neko
		result.alloced = result.length;
		#end
		return result;
	}
	
	
	#if cpp inline #end function push(inByte:Int)
	{
		#if cpp
		b[length++] = untyped inByte;
		#else
		ensureElem(length, false);
		untyped __dollar__sset(b, length++, inByte & 0xff);
		#end
	}
	
	
	inline function push_uncheck(inByte:Int)
	{
		#if cpp
		untyped b.__unsafe_set(length++, inByte);
		#else
		untyped __dollar__sset(b, length++, inByte & 0xff);
		#end
	}
	
	
	public inline function readBoolean():Bool
	{
		return (position + 1 < length) ? __get(position++) != 0 : ThrowEOFi() != 0;
	}
	
	
	public inline function readByte():Int
	{
		return (position < length) ? __get(position++) : ThrowEOFi();
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
		#else
		var b1 = b;
		var b2 = outData.b;
		var p = position;
		for (i in 0...inLen)
			b2[inOffset + i] = b1[p + i];
		#end
		position += inLen;
	}
	
	
	public function readDouble():Float
	{
		if (position + 8 > length)
			ThrowEOFi();
		
		#if neko
		var bytes = new Bytes(8, untyped __dollar__ssub(b, position, 8));
		#elseif cpp
		var bytes = new Bytes(8, b.slice(position, position + 8));
		#end
		
		position += 8;
		return _double_of_bytes(bytes.b, bigEndian);
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
		
		#if neko
		var bytes = new Bytes(4, untyped __dollar__ssub(b, position, 4));
		#elseif cpp
		var bytes = new Bytes(4, b.slice(position, position + 4));
		#end
		
		position += 4;
		return _float_of_bytes(bytes.b, bigEndian);
	}


	public function readInt():Int
	{
		var ch1 = readByte();
		var ch2 = readByte();
		var ch3 = readByte();
		var ch4 = readByte();
		return bigEndian ? (ch1 << 24) | (ch2 << 16) | (ch3 << 8) | ch4 : (ch4 << 24) | (ch3 << 16) | (ch2 << 8) | ch1;
	}
	
	
	public function readShort():Int
	{
		var ch1 = readByte();
		var ch2 = readByte();
		var val = bigEndian ? (ch1 << 8) | ch2 : (ch2 << 8) + ch1;
		return (val >= 0x8000 ) ? 65534 - val : val;
	}
	
	
	inline public function readUnsignedByte():Int
	{
		return readByte();
	}
	
	
	public function readUnsignedInt():Int
	{
		var ch1 = readByte();
		var ch2 = readByte();
		var ch3 = readByte();
		var ch4 = readByte();
		return bigEndian ? (ch1 << 24) | (ch2 << 16) | (ch3 << 8) | ch4 : (ch4 << 24) | (ch3 << 16) | (ch2 << 8) | ch1;
	}
	
	
	public function readUnsignedShort():Int
	{
		var ch1 = readByte();
		var ch2 = readByte();
		return bigEndian ? (ch1 << 8) | ch2 : (ch2 << 8) + ch1;
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
		#end
	}
	
	
	public function setLength(inLength:Int):Void
	{
		if (inLength > 0)
			ensureElem(inLength - 1, false);
		length = inLength;
	}
	
	
	private function ThrowEOFi():Int
	{
		throw new EOFError();
		return 0;
	}
	
	
	public function uncompress(algorithm:String = "")
	{
		#if neko
		var src = alloced == length ? this : sub(0, length);
		#else
		var src = this;
		#end
		
		var result = Uncompress.run(src, null);
		b = result.b;
		length = result.length;
		position = 0;
		#if neko
		alloced = length;
		#end
	}
	
	
	public function writeBoolean(value:Bool)
	{
		push(value ? 1 : 0);
	}
	
	
	inline public function writeByte(value:Int)
	{
		push(value);
	}
	
	
	public function writeBytes(bytes:Bytes, inOffset:Int = 0, inLength:Int = 0)
	{
		if (inLength == 0)
			inLength = bytes.length;
		ensureElem(length + inLength - 1, false);
		var olen = length;
		length += inLength;
		blit(olen, bytes, inOffset, inLength);
	}
	
	
	public function writeDouble(x:Float)
	{
		#if neko
		var bytes = new Bytes(8, _double_bytes(x, bigEndian));
		#elseif cpp
		var bytes = Bytes.ofData(_double_bytes(x, bigEndian));
		#end
		writeBytes(bytes);
	}
	
	
	#if !no_nme_io
	public function writeFile(inString:String):Void
	{
		nme_byte_array_overwrite_file(inString, this);
	}
	#end
	
	
	public function writeFloat(x:Float)
	{
		#if neko
		var bytes = new Bytes(4, _float_bytes(x, bigEndian));
		#elseif cpp
		var bytes = Bytes.ofData(_float_bytes(x, bigEndian));
		#end
		writeBytes(bytes);
	}
	
	
	public function writeInt(value:Int)
	{
		ensureElem(length + 3, false);
		if (bigEndian)
		{
			push_uncheck(value >> 24);
			push_uncheck(value >> 16);
			push_uncheck(value >> 8);
			push_uncheck(value);
		}
		else
		{
			push_uncheck(value);
			push_uncheck(value >> 8);
			push_uncheck(value >> 16);
			push_uncheck(value >> 24);
		}
	}
	
	
	// public function writeMultiByte(value:String, charSet:String)
	// public function writeObject(object:*)
	
	
	public function writeShort(value:Int)
	{
		ensureElem(length + 1, false);
		if (bigEndian)
		{
			push_uncheck(value >> 8);
			push_uncheck(value);
		}
		else
		{
			push_uncheck(value);
			push_uncheck(value >> 8);
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
		writeBytes(bytes);
	}
	
	
	public function writeUTFBytes(s:String)
	{
		#if neko
		var bytes = new Bytes(s.length, untyped s.__s);
		#else
		var bytes = Bytes.ofString(s);
		#end
		writeBytes(bytes);
	}
	
	
	
	// Getters & Setters
	
	
	
	/**
	 * @private
	 */
	public function nmeGetBytesAvailable():Int { return length - position; }
	
	/**
	 * @private
	 */
	public function nmeGetEndian():String { return bigEndian ? Endian.BIG_ENDIAN : Endian.LITTLE_ENDIAN; }
	
	/**
	 * @private
	 */
	public function nmeSetEndian(s:String):String { bigEndian = (s == Endian.BIG_ENDIAN); return s; }
	
	
	
	// Native Methods
	
	
	
	private static var _double_bytes = Lib.load("std", "double_bytes", 2);
	private static var _double_of_bytes = Lib.load("std", "double_of_bytes", 2);
	private static var _float_bytes = Lib.load("std", "float_bytes", 2);
	private static var _float_of_bytes = Lib.load("std", "float_of_bytes", 2);

	#if !no_nme_io
	private static var nme_byte_array_overwrite_file = Loader.load("nme_byte_array_overwrite_file", 2);
	private static var nme_byte_array_read_file = Loader.load("nme_byte_array_read_file", 1);
	#end
	
}


#elseif js

import haxe.io.Input;
import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.io.BytesBuffer;

import nme.errors.IOError;

import Html5Dom;

class ByteArray {

	var data : Array<Int>;
	var bigEndian : Bool;

	public var bytesAvailable(GetBytesAvailable,null) : Int;
	public var endian(__GetEndian,__SetEndian) : Endian;
	public var objectEncoding : Int;

	public var position : Int;
	public var length(GetLength,null) : Int;

	var TWOeN23 : Float;
	var pow : Float->Float->Float;
	var LN2 : Float;
	var abs : Float->Float;
	var log : Float->Float;
	//var fromCharCode : Int -> String;
	var floor : Float->Int;
	//var parseInt : String->Int->Int;

	inline function GetBytesAvailable():Int
	{
		return length - position;
	}

	function readString( len : Int ) : String {
		var bytes = Bytes.alloc(len);
		readFullBytes(bytes,0,len);
		return bytes.toString();
	}

	function readFullBytes( bytes : Bytes, pos : Int, len : Int ) {
		for ( i in pos...pos+len )
			data[this.position++] = bytes.get(i);
	}

	function read( nbytes : Int ) : Bytes 
	{
		var s = new ByteArray();
		readBytes(s,0,nbytes);
		return Bytes.ofData(s.data);
	}

	function GetLength()
	{
		return data.length;
	}

	public function new() {
		this.position = 0;
		this.data = [];

		this.TWOeN23 = Math.pow(2, -23);
		this.pow = Math.pow;
		this.LN2 = Math.log(2);
		this.abs = Math.abs;
		this.log = Math.log;
		//this.fromCharCode = String.fromCharCode;
		this.floor = Math.floor;
		//this.parseInt = untyped window.parseInt;

		this.bigEndian = false;
	}

	public function readByte() : Int 
	{
		if( this.position >= this.length )
			throw new IOError("Read error - Out of bounds");
		return data[this.position++];
	}

	public function readBytes(bytes : ByteArray, ?offset : UInt, ?length : UInt)
	{
		if( offset < 0 || length < 0 || offset + length > data.length )
			throw new IOError("Read error - Out of bounds");

		if( data.length == 0 && length > 0 )
			throw new IOError("Read error - Out of bounds");

		if( data.length < length )
			length = data.length;

		var b1 = data;
		var b2 = bytes;
		b2.position = offset;
		for( i in 0...length )
			b2.writeByte( b1[this.position+i] );
		b2.position = offset;

		this.position += length;
	}
	
	public function writeByte(value : Int)
	{
		data[this.position++] = value;
	}

	public function writeBytes(bytes : ByteArray, ?offset : UInt, ?length : UInt) 
	{
		if( offset < 0 || length < 0 || offset + length > bytes.length ) throw new IOError("Write error - Out of bounds");
		var b2 = bytes;
		b2.position = offset;
		for( i in 0...length )
			data[this.position++] = b2.readByte();

	}

	public function readBoolean() 
	{
		return this.readByte() == 1 ? true : false;
	}

	public function writeBoolean(value : Bool) 
	{
		this.writeByte(value?1:0);
	}

	public function readDouble() : Float 
	{
		var data = this.data, pos, b1, b2, b3, b4, b5, b6, b7, b8;
		if (bigEndian) {
			pos = (this.position += 8) - 8;
			b1 = data[pos] & 0xFF;
			b2 = data[++pos] & 0xFF;
			b3 = data[++pos] & 0xFF;
			b4 = data[++pos] & 0xFF;
			b5 = data[++pos] & 0xFF;
			b6 = data[++pos] & 0xFF;
			b7 = data[++pos] & 0xFF;
			b8 = data[++pos] & 0xFF;
		} else {
			pos = (this.position += 8);
			b1 = data[--pos] & 0xFF;
			b2 = data[--pos] & 0xFF;
			b3 = data[--pos] & 0xFF;
			b4 = data[--pos] & 0xFF;
			b5 = data[--pos] & 0xFF;
			b6 = data[--pos] & 0xFF;
			b7 = data[--pos] & 0xFF;
			b8 = data[--pos] & 0xFF;
		}
		var sign = 1 - ((b1 >> 7) << 1);									// sign = bit 0
		var exp = (((b1 << 4) & 0x7FF) | (b2 >> 4)) - 1023;					// exponent = bits 1..11

		// This crazy toString() stuff works around the fact that js ints are
		// only 32 bits and signed, giving us 31 bits to work with
		var sig =untyped {
		 	parseInt(((((b2&0xF) << 16) | (b3 << 8) | b4 ) * pow(2, 32)).toString(2), 2) +
			parseInt(((b5 >> 7) * pow(2,31)).toString(2), 2) +
			parseInt((((b5&0x7F) << 24) | (b6 << 16) | (b7 << 8) | b8).toString(2), 2);	// significand = bits 12..63
		}

		if (sig == 0 && exp == -1023)
			return 0.0;

		return sign*(1.0 + pow(2, -52)*sig)*pow(2, exp);
	}

	public function writeDouble(x : Float) 
	{
		if (x==0.0) {
			for (_ in 0...8) 
				data[this.position++] = 0;
		}

		var exp = floor(log(abs(x)) / LN2);
		var sig : Int = floor(abs(x) / pow(2, exp) * pow(2, 52));
		var sig_h = (sig & cast 34359738367);
		var sig_l = floor((sig / pow(2,32)) );
		var b1 = (exp + 0x3FF) >> 4 | (exp>0 ? ((x<0) ? 1<<7 : 1<<6) : ((x<0) ? 1<<7 : 0)),
		    b2 = (exp + 0x3FF) << 4 & 0xFF | (sig_l >> 16 & 0xF),
		    b3 = (sig_l >> 8) & 0xFF,
		    b4 = sig_l & 0xFF,
		    b5 = (sig_h >> 24) & 0xFF,
		    b6 = (sig_h >> 16) & 0xFF,
		    b7 = (sig_h >> 8) & 0xFF,
		    b8 = sig_h & 0xFF;

		if (bigEndian) {
			data[this.position++] = b1;
			data[this.position++] = b2;
			data[this.position++] = b3;
			data[this.position++] = b4;
			data[this.position++] = b5;
			data[this.position++] = b6;
			data[this.position++] = b7;
			data[this.position++] = b8;
		} else {
			data[this.position++] = b8;
			data[this.position++] = b7;
			data[this.position++] = b6;
			data[this.position++] = b5;
			data[this.position++] = b4;
			data[this.position++] = b3;
			data[this.position++] = b2;
			data[this.position++] = b1;
		}
	}

	public function readFloat() : Float 
	{
		var data = this.data, pos, b1, b2, b3, b4;

		if (bigEndian) {
			pos = (this.position += 4) - 4;
			b1 = data[pos] & 0xFF;
			b2 = data[++pos] & 0xFF;
			b3 = data[++pos] & 0xFF;
			b4 = data[++pos] & 0xFF;
		} else {
			pos = (this.position += 4);
			b1 = data[--pos] & 0xFF;
			b2 = data[--pos] & 0xFF;
			b3 = data[--pos] & 0xFF;
			b4 = data[--pos] & 0xFF;
		}

		var sign = 1 - ((b1 >> 7) << 1);
		var exp = (((b1 << 1) & 0xFF) | (b2 >> 7)) - 127;
		var sig = ((b2 & 0x7F) << 16) | (b3 << 8) | b4;
		if (sig == 0 && exp == -127)
			return 0.0;

		return sign*(1 + TWOeN23*sig)*pow(2, exp);
	}

	public function writeFloat( x : Float ) 
	{
		if (x==0.0) {
			for (_ in 0...4)
				data[this.position++] = 0;
		}

		var exp = floor(log(abs(x)) / LN2);
		var sig = (floor(abs(x) / pow(2, exp) * pow(2, 23)) & 0x7FFFFF);
		var b1 = (exp + 0x7F) >> 1 | (exp>0 ? ((x<0) ? 1<<7 : 1<<6) : ((x<0) ? 1<<7 : 0)),
		    b2 = (exp + 0x7F) << 7 & 0xFF | (sig >> 16 & 0x7F),
		    b3 = (sig >> 8) & 0xFF,
		    b4 = sig & 0xFF;

		if (bigEndian) {
			data[this.position++] = b1;
			data[this.position++] = b2;
			data[this.position++] = b3;
			data[this.position++] = b4;
		} else {
			data[this.position++] = b4;
			data[this.position++] = b3;
			data[this.position++] = b2;
			data[this.position++] = b1;
		}
	}

	public function readInt()
	{
		var ch1,ch2,ch3,ch4;
		if( bigEndian ) {
			ch4 = readByte();
			ch3 = readByte();
			ch2 = readByte();
			ch1 = readByte();
		} else {
			ch1 = readByte();
			ch2 = readByte();
			ch3 = readByte();
			ch4 = readByte();
		}
		return ch1 | (ch2 << 8) | (ch3 << 16) | (ch4 << 24);
	}

	public function writeInt(value : Int)
	{
		if( bigEndian ) 
		{
			writeByte(value >>> 24);
			writeByte((value >> 16) & 0xFF);
			writeByte((value >> 8) & 0xFF);
			writeByte(value & 0xFF);
		} else {
			writeByte(value & 0xFF);
			writeByte((value >> 8) & 0xFF);
			writeByte((value >> 16) & 0xFF);
			writeByte(value >>> 24);
		}
	}

	public function readShort()
	{
		var ch1 = readByte();
		var ch2 = readByte();
		var n = bigEndian ? ch2 | (ch1 << 8) : ch1 | (ch2 << 8);
		if( n & 0x8000 != 0 )
			return n - 0x10000;
		return n;
	}

	public function writeShort(value : Int)
	{
		if( value < -0x8000 || value >= 0x8000 ) throw new IOError("Write error - overflow");
		writeUnsignedShort(value & 0xFFFF);
	}

	public function writeUnsignedShort( value : Int ) 
	{
		if( value < 0 || value >= 0x10000 ) throw new IOError("Write error - overflow");
		if( endian == Endian.BIG_ENDIAN ) {
			writeByte(value >> 8);
			writeByte(value & 0xFF);
		} else {
			writeByte(value & 0xFF);
			writeByte(value >> 8);
		}
	}

	public function readUTF()
	{
		var len = readShort();

		var bytes = Bytes.ofData( data );
		return bytes.readString( 2, len );
	}

	public function writeUTF(value : String)
	{
		var bytes = Bytes.ofString( value );
		writeShort( bytes.length );
		for ( i in 0...bytes.length )
			data[this.position++] = bytes.get(i);
	}

	public function writeUTFBytes(value : String)
	{
		var bytes = Bytes.ofString( value );
		for ( i in 0...bytes.length )
			data[this.position++] = bytes.get(i);
	}

	public function readUTFBytes(len:Int)
	{
		var bytes = Bytes.ofData( data );
		return bytes.readString( 0, len );
	}

	public function readUnsignedByte():Int
	{
		return readByte();
	}

	public function readUnsignedShort():Int
	{
		return readShort();
	}

	public function readUnsignedInt():Int
	{
		return readInt();
	}

	public function writeUnsignedInt( value : Int )
	{
		writeInt( value );
	}

	public function __GetEndian() : Endian
	{
		if ( bigEndian == true )
		{
			return Endian.BIG_ENDIAN;
		} else {
			return Endian.LITTLE_ENDIAN;
		}
	}
	public function __SetEndian( endian : Endian ) : Endian
	{
		if ( endian == Endian.BIG_ENDIAN )
		{
			bigEndian = true;
		} else {
			bigEndian = false;
		}

		return endian;
	}
}

#else
typedef ByteArray = flash.utils.ByteArray;
#end
