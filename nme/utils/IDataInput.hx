package nme.utils;
#if code_completion


extern interface IDataInput {
	var bytesAvailable(default,null) : UInt;
	var endian : Endian;
	var objectEncoding : UInt;
	function readBoolean() : Bool;
	function readByte() : Int;
	function readBytes(bytes : ByteArray, offset : UInt = 0, length : UInt = 0) : Void;
	function readDouble() : Float;
	function readFloat() : Float;
	function readInt() : Int;
	function readMultiByte(length : UInt, charSet : String) : String;
	function readObject() : Dynamic;
	function readShort() : Int;
	function readUTF() : String;
	function readUTFBytes(length : UInt) : String;
	function readUnsignedByte() : UInt;
	function readUnsignedInt() : UInt;
	function readUnsignedShort() : UInt;
}


#elseif (cpp || neko)
typedef IDataInput = neash.utils.IDataInput;
#elseif js
typedef IDataInput = jeash.utils.IDataInput;
#else
typedef IDataInput = flash.utils.IDataInput;
#end