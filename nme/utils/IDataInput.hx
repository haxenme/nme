package nme.utils;
#if display


extern interface IDataInput {
	var bytesAvailable(default,null) : Int;
	var endian : Endian;
	var objectEncoding : Int;
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
}


#elseif (cpp || neko)
typedef IDataInput = native.utils.IDataInput;
#elseif js
typedef IDataInput = browser.utils.IDataInput;
#else
typedef IDataInput = flash.utils.IDataInput;
#end
