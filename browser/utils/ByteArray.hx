package browser.utils;


import browser.errors.IOError;
import browser.Html5Dom;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.BytesData;
import haxe.io.Input;

#if format
import format.tools.Inflate;
#end


class ByteArray #if js_can_implement_array_access implements ArrayAccess<Int> #end {
	
	
	public var bytesAvailable (get_bytesAvailable, null):Int;
	public var endian (get_endian, set_endian):String;
	public var length (default, set_length):Int;
	public var objectEncoding:Int;
	public var position:Int;
	
	private var allocated:Int;
	private var byteView:Uint8Array;
	private var data:DataView;
	private var littleEndian:Bool;
	
	
	public function new ():Void {
		
		var len = 0;
		this.position = 0;
		this.length = len;
		this.allocated = len;

		// NOTE: default ByteArray endian is BIG_ENDIAN
		this.littleEndian = false;

		_nmeResizeBuffer (allocated);
		//this.byteView = untyped __new__("Uint8Array", allocated);
		//this.data = untyped __new__("DataView", this.byteView.buffer);
		
	}
	
	
	#if js_can_implement_array_access // ArrayAccess
	public function __get (pos:Int):Int { return data.getUint8 (pos); }
	public function __set (pos:Int, v:Int):Void { data.setUint8 (pos, v); }
	#end
	
	
	private function _getUTFBytesCount (value:String):Int {
		
		var count:Int = 0;
		// utf8-decode
		
		for (i in 0...value.length) {
			
			var c = StringTools.fastCodeAt (value, i);
			
			if (c <= 0x7F) {
				
				count += 1;
				
			} else if (c <= 0x7FF) {
				
				count += 2;
				
			} else if (c <= 0xFFFF) {
				
				count += 3;
				
			} else {
				
				count += 4;
				
			}
			
		}
		
		return count;
		
	}
	
	
	private function _nmeResizeBuffer (len:Int):Void {
		
		var oldByteView:Uint8Array = this.byteView;
		var newByteView:Uint8Array = untyped __new__("Uint8Array", len);
		
		if (oldByteView != null) newByteView.set (oldByteView);
		
		this.byteView = newByteView;
		this.data = untyped __new__("DataView", newByteView.buffer);
		
	}
	
	
	private function ensureWrite (lengthToEnsure:Int, updateLength:Bool = true):Void {
		
		if (updateLength) {
			
			if (this.length < lengthToEnsure) this.length = lengthToEnsure;
			
		} else if (lengthToEnsure > allocated) {
			
			_nmeResizeBuffer (Std.int (Math.max (lengthToEnsure, allocated * 2)));
			
		}
		
	}
	
	
	public function nmeGet (pos:Int):Int {
		
		return data.getUint8 (pos);
		
	}
	
	
	public function nmeGetBuffer () {
		
		return data.buffer;
		
	}
	
	
	public static function nmeOfBuffer (buffer:ArrayBuffer):ByteArray {
		
		var bytes = new ByteArray ();
		bytes.length = buffer.byteLength;
		bytes.data = untyped __new__("DataView", buffer);
		bytes.byteView = untyped __new__("Uint8Array", buffer);
		return bytes;
		
	}
	
	
	public function nmeSet (pos:Int, v:Int):Void {
		
		data.setUint8 (pos, v);
		
	}
	
	
	public function readBoolean ():Bool {
		
		return (this.readByte () != 0);
		
	}
	
	
	public function readByte ():Int {
		
		return data.getUint8 (this.position++);
		
	}
	
	
	public function readBytes (bytes:ByteArray, ?offset:Int, ?length:Int):Void {
		
		if (offset < 0 || length < 0) {
			
			throw new IOError("Read error - Out of bounds");
			
		}
		
		if (offset == null) offset = 0;
		if (length == null) length = this.length;
		
		bytes.ensureWrite (offset + length);
		
		bytes.byteView.set (byteView.subarray (this.position, this.position + length), offset);
		bytes.position = offset;
		
		this.position += length;
		if (bytes.position + length > bytes.length) bytes.length = bytes.position + length;
		
	}
	
	
	public function readDouble ():Float {
		
		var double = data.getFloat64 (this.position, littleEndian);
		this.position += 8;
		return double;
		
	}
	
	
	public function readFloat ():Float {
		
		var float = data.getFloat32 (this.position, littleEndian);
		this.position += 4;
		return float;
		
	}
	
	
	private function readFullBytes (bytes:Bytes, pos:Int, len:Int):Void {
		
		// NOTE: It is used somewhere?
		
		ensureWrite (len);
		
		for (i in pos...(pos + len)) {
			
			data.setInt8 (this.position++, bytes.get (i));
			
		}
		
	}
	
	
	public function readInt ():Int {
		
		var int = data.getInt32 (this.position, littleEndian);
		this.position += 4;
		return int;
		
	}
	
	
	public function readShort ():Int {
		
		var short = data.getInt16 (this.position, littleEndian);
		this.position += 2;
		return short;
		
	}
	
	
	public function readUnsignedByte ():Int {
		
		return data.getUint8 (this.position++);
		
	}
	
	
	public function readUnsignedInt ():Int {
		
		var uInt = data.getUint32 (this.position, littleEndian);
		this.position += 4;
		return uInt;
		
	}
	
	
	public function readUnsignedShort ():Int {
		
		var uShort = data.getUint16 (this.position, littleEndian);
		this.position += 2;
		return uShort;
		
	}
	
	
	public function readUTF ():String {
		
		var bytesCount = readUnsignedShort ();
		return readUTFBytes (bytesCount);
		
	}
	
	
	public function readUTFBytes (len:Int):String {
		
		var value = "";
		var max = this.position + len;
		
		// utf8-encode
		while (this.position < max) {
			
			var c = data.getUint8 (this.position++);
			
			if (c < 0x80) {
				
				if (c == 0) break;
				value += String.fromCharCode (c);
				
			} else if (c < 0xE0) {
				
				value += String.fromCharCode (((c & 0x3F) << 6) | (data.getUint8 (this.position++) & 0x7F));
				
			} else if (c < 0xF0) {
				
				var c2 = data.getUint8 (this.position++);
				value += String.fromCharCode (((c & 0x1F) << 12) | ((c2 & 0x7F) << 6) | (data.getUint8 (this.position++) & 0x7F));
				
			} else {
				
				var c2 = data.getUint8 (this.position++);
				var c3 = data.getUint8 (this.position++);
				value += String.fromCharCode (((c & 0x0F) << 18) | ((c2 & 0x7F) << 12) | ((c3 << 6) & 0x7F) | (data.getUint8 (this.position++) & 0x7F));
				
			}
			
		}
		
		return value;
		
	}
	
	
	#if format
	public function uncompress ():Void {
		
		var bytes = Bytes.ofData (cast byteView);
		var buf = Inflate.run (bytes).getData ();
		this.byteView = untyped __new__("Uint8Array", buf);
		this.data = untyped __new__("DataView", byteView.buffer);
		this.length = byteView.buffer.byteLength;
		
	}
	#end
	
	
	public function writeBoolean (value:Bool):Void {
		
		this.writeByte (value ? 1 : 0);
		
	}
	
	
	public function writeByte (value:Int):Void {
		
		ensureWrite (this.position + 1);
		data.setInt8 (this.position, value);
		this.position += 1;
		
	}
	
	
	public function writeBytes (bytes:ByteArray, ?offset:UInt, ?length:UInt):Void {
		
		if (offset < 0 || length < 0) throw new IOError ("Write error - Out of bounds");
		
		ensureWrite (this.position + length);
		byteView.set (bytes.byteView.subarray (offset, offset + length), this.position);
		this.position += length;
		
	}
	
	
	public function writeDouble (x:Float):Void {
		
		ensureWrite (this.position + 8);
		data.setFloat64 (this.position, x, littleEndian);
		this.position += 8;
		
	}
	
	
	public function writeFloat (x:Float):Void {
		
		ensureWrite (this.position + 4);
		data.setFloat32 (this.position, x, littleEndian);
		this.position += 4;
		
	}
	
	
	public function writeInt (value:Int):Void {
		
		ensureWrite (this.position + 4);
		data.setInt32 (this.position, value, littleEndian);
		this.position += 4;
		
	}
	
	
	public function writeShort (value:Int):Void {
		
		ensureWrite (this.position + 2);
		data.setInt16 (this.position, value, littleEndian);
		this.position += 2;
		
	}
	
	
	public function writeUnsignedInt (value:Int):Void {
		
		ensureWrite (this.position + 4);
		data.setUint32 (this.position, value, littleEndian);
		this.position += 4;
		
	}
	
	
	public function writeUnsignedShort (value:Int):Void {
		
		ensureWrite (this.position + 2);
		data.setUint16 (this.position, value, littleEndian);
		this.position += 2;
		
	}
	
	
	public function writeUTF (value:String):Void {
		
		writeUnsignedShort (_getUTFBytesCount (value));
		writeUTFBytes (value);
		
	}
	
	
	public function writeUTFBytes (value:String):Void {
		
		// utf8-decode
		for (i in 0...value.length) {
			
			var c = StringTools.fastCodeAt (value, i);
			
			if (c <= 0x7F) {
				
				writeByte (c);
				
			} else if (c <= 0x7FF) {
				
				writeByte (0xC0 | (c >> 6));
				writeByte (0x80 | (c & 63));
				
			} else if (c <= 0xFFFF) {
				
				writeByte (0xE0 | (c >> 12));
				writeByte (0x80 | ((c >> 6) & 63));
				writeByte (0x80 | (c & 63));
				
			} else {
				
				writeByte (0xF0 | (c >> 18));
				writeByte (0x80 | ((c >> 12) & 63));
				writeByte (0x80 | ((c >> 6) & 63));
				writeByte (0x80 | (c & 63));
				
			}
			
		}
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function get_bytesAvailable ():Int { return length - position; }
	
	
	public function get_endian ():String {
		
		return (littleEndian == true) ? Endian.LITTLE_ENDIAN : Endian.BIG_ENDIAN;
		
	}
	
	
	public function set_endian (endian:String):String {
		
		littleEndian = (endian == Endian.LITTLE_ENDIAN);
		return endian;
		
	}
	
	
	private function set_length (value:Int):Int {
		
		_nmeResizeBuffer (value);
		length = value;
		allocated = value;
		return value;
		
	}
	
	
}