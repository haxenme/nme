package nme.utils;
#if code_completion


extern class ByteArray /*implements IDataOutput,*/ implements IDataInput, implements ArrayAccess<Int> {
	var bytesAvailable(default,null) : Int;
	var endian : Endian;
	var length : Int;
	var objectEncoding : Int;
	var position : Int;
	function new() : Void;
	@:require(flash10) function clear() : Void;
	function compress(#if flash11 ?algorithm : CompressionAlgorithm #end) : Void;
	@:require(flash10) function deflate() : Void;
	@:require(flash10) function inflate() : Void;
	function readBoolean() : Bool;
	function readByte() : Int;
	function readBytes(bytes : ByteArray, offset : Int = 0, length : Int = 0) : Void;
	function readDouble() : Float;
	function readFloat() : Float;
	function readInt() : Int;
	function readMultiByte(length : Int, charSet : String) : String;
	function readObject() : Dynamic;
	function readShort() : Int;
	function readUTF() : String;
	function readUTFBytes(length : Int) : String;
	function readUnsignedByte() : Int;
	function readUnsignedInt() : Int;
	function readUnsignedShort() : Int;
	function toString() : String;
	function uncompress(#if flash11 ?algorithm : CompressionAlgorithm #end) : Void;
	function writeBoolean(value : Bool) : Void;
	function writeByte(value : Int) : Void;
	function writeBytes(bytes : ByteArray, offset : Int = 0, length : Int = 0) : Void;
	function writeDouble(value : Float) : Void;
	function writeFloat(value : Float) : Void;
	function writeInt(value : Int) : Void;
	function writeMultiByte(value : String, charSet : String) : Void;
	function writeObject(object : Dynamic) : Void;
	function writeShort(value : Int) : Void;
	function writeUTF(value : String) : Void;
	function writeUTFBytes(value : String) : Void;
	function writeUnsignedInt(value : Int) : Void;
	static var defaultObjectEncoding : Int;
}


#elseif (cpp || neko)
typedef ByteArray = neash.utils.ByteArray;
#elseif js
typedef ByteArray = jeash.utils.ByteArray;
#else
typedef ByteArray = flash.utils.ByteArray;
#end