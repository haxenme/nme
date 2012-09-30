/**
 * Copyright (c) 2010, Jeash contributors.
 * 
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

package jeash.utils;

import haxe.io.Input;
import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.io.BytesBuffer;

import jeash.errors.IOError;

import jeash.Html5Dom;

class ByteArray
#if js_can_implement_array_access
	implements ArrayAccess<Int>
#end
{

	var data : DataView;
	var byteView : Uint8Array;
	var littleEndian : Bool;

	public var bytesAvailable(jeashGetBytesAvailable, null) : Int;
	public var endian(jeashGetEndian, jeashSetEndian) : String;
	public var objectEncoding : Int;

	public var position : Int;
	public var length : Int;
	private var allocated : Int = 0;

	public function new():Void {
		var len:Int = 0;
		this.position = 0;
		this.length = len;
		this.allocated = len;

		// NOTE: default ByteArray endian is BIG_ENDIAN
		this.littleEndian = false;

		_jeashResizeBuffer(allocated);
		//this.byteView = untyped __new__("Uint8Array", allocated);
		//this.data = untyped __new__("DataView", this.byteView.buffer);
	}

	private function _jeashResizeBuffer(len:Int) {
		var oldByteView:Uint8Array = this.byteView;
		var newByteView:Uint8Array = untyped __new__("Uint8Array", len);

		if (oldByteView != null) newByteView.set(oldByteView);

		this.byteView = newByteView;
		this.data = untyped __new__("DataView", newByteView.buffer);
	}

	function jeashGetBytesAvailable():Int { return length - position; }
	
	// ArrayAccess
	#if js_can_implement_array_access
	public function __get(pos:Int):Int { return data.getUint8(pos); }
	public function __set(pos:Int, v:Int):Void { data.setUint8(pos, v); }
	#end
	
	public function jeashGet(pos:Int):Int {
		return data.getUint8(pos);
	}
	
	public function jeashSet(pos:Int, v:Int):Void {
		data.setUint8(pos, v);
	}

	// NOTE: It is used somewhere?
	function readFullBytes( bytes : Bytes, pos : Int, len : Int ) {
		ensureWrite(len);
		for ( i in pos...pos+len )
			data.setInt8(this.position++, bytes.get(i));
	}
	
	private function ensureWrite(lengthToEnsure:Int, updateLength:Bool= true):Void {
		if (lengthToEnsure > allocated) {
			_jeashResizeBuffer(Std.int(Math.max(lengthToEnsure, allocated * 2)));
		}
		if (updateLength) {
			if (this.length < lengthToEnsure) this.length = lengthToEnsure;
		}
	}

	public function readByte() : Int {
		return data.getUint8(this.position++);
	}

	public function readBytes(bytes : ByteArray, ?offset : UInt, ?length : UInt) {
		if(offset < 0 || length < 0)
			throw new IOError("Read error - Out of bounds");

		if (offset == null) offset = 0;
		if (length == null) length = this.length;

		bytes.ensureWrite(offset + length);

		bytes.byteView.set(byteView.subarray(this.position, this.position+length), offset);
		bytes.position = offset;

		this.position += length;
		if (bytes.position+length > bytes.length) bytes.length = bytes.position+length;
	}
	
	public function writeByte(value : Int) {
		ensureWrite(this.position + 1);
		
		data.setInt8(this.position, value);
		this.position += 1;
	}

	public function writeBytes(bytes : ByteArray, ?offset : UInt, ?length : UInt) {
		if (offset < 0 || length < 0)  throw new IOError("Write error - Out of bounds");

		ensureWrite(this.position + length);

		byteView.set(bytes.byteView.subarray(offset, offset+length), this.position);
		this.position += length;
	}

	public function readBoolean():Bool {
		return (this.readByte() != 0);
	}

	public function writeBoolean(value : Bool):Void {
		this.writeByte(value?1:0);
	}

	public function readDouble():Float {
		var double = data.getFloat64(this.position, littleEndian);
		this.position += 8;
		return double;
	}

	public function writeDouble(x : Float):Void {
		ensureWrite(this.position + 8);

		data.setFloat64(this.position, x, littleEndian);
		this.position += 8;
	}

	public function readFloat() : Float {
		var float = data.getFloat32(this.position, littleEndian);
		this.position += 4;
		return float;
	}

	public function writeFloat( x : Float ):Void {
		ensureWrite(this.position + 4);

		data.setFloat32(this.position, x, littleEndian);
		this.position += 4;
	}

	public function readInt():Int {
		var int = data.getInt32(this.position, littleEndian);
		this.position += 4;
		return int;
	}

	public function writeInt(value : Int):Void {
		ensureWrite(this.position + 4);

		data.setInt32(this.position, value, littleEndian);
		this.position += 4;
	}

	public function readShort():Int {
		var short = data.getInt16(this.position, littleEndian);
		this.position += 2;
		return short;
	}

	public function writeShort(value : Int):Void {
		ensureWrite(this.position + 2);

		data.setInt16(this.position, value, littleEndian);
		this.position += 2;
	}

	public function readUnsignedShort():Int {
		var uShort = data.getUint16(this.position, littleEndian);
		this.position += 2;
		return uShort;
	}

	public function writeUnsignedShort( value : Int ):Void {
		ensureWrite(this.position + 2);

		data.setUint16(this.position, value, littleEndian);
		this.position += 2;
	}

	public function readUTF():String {
		var bytesCount:Int = readUnsignedShort();
		return readUTFBytes(bytesCount);
	}

	public function writeUTF(value : String):Void {
		writeUnsignedShort(_getUTFBytesCount(value));
		writeUTFBytes(value);
	}
	
	private function _getUTFBytesCount(value : String):Int {
		var count:Int = 0;
		// utf8-decode
		for( i in 0...value.length ) {
			var c : Int = StringTools.fastCodeAt(value, i);
			if( c <= 0x7F ) count += 1;
			else if( c <= 0x7FF ) count += 2;
			else if( c <= 0xFFFF ) count += 3;
			else count += 4;
		}
		return count;
	}

	public function writeUTFBytes(value : String):Void {
		// utf8-decode
		for( i in 0...value.length ) {
			var c : Int = StringTools.fastCodeAt(value, i);
			if( c <= 0x7F ) {
				writeByte(c);
			} else if( c <= 0x7FF ) {
				writeByte(0xC0 | (c >> 6));
				writeByte(0x80 | (c & 63));
			} else if( c <= 0xFFFF ) {
				writeByte(0xE0 | (c >> 12));
				writeByte(0x80 | ((c >> 6) & 63));
				writeByte(0x80 | (c & 63));
			} else {
				writeByte(0xF0 | (c >> 18));
				writeByte(0x80 | ((c >> 12) & 63));
				writeByte(0x80 | ((c >> 6) & 63));
				writeByte(0x80 | (c & 63));
			}
		}
	}

	public function readUTFBytes(len:Int):String {
		var value = "";
		var fcc = String.fromCharCode;
		var max = this.position + len;

		// utf8-encode
		while( this.position < max ) {
			var c = data.getUint8(this.position++);
			if( c < 0x80 ) {
				if( c == 0 ) break;
				value += fcc(c);
			} else if( c < 0xE0 )
				value += fcc( ((c & 0x3F) << 6) | (data.getUint8(this.position++) & 0x7F) );
			else if( c < 0xF0 ) {
				var c2 = data.getUint8(this.position++);
				value += fcc( ((c & 0x1F) << 12) | ((c2 & 0x7F) << 6) | (data.getUint8(this.position++) & 0x7F) );
			} else {
				var c2 = data.getUint8(this.position++);
				var c3 = data.getUint8(this.position++);
				value += fcc( ((c & 0x0F) << 18) | ((c2 & 0x7F) << 12) | ((c3 << 6) & 0x7F) | (data.getUint8(this.position++) & 0x7F) );
			}
		}
		return value;
	}

	public function readUnsignedByte():Int {
		return data.getUint8(this.position++);
	}

	public function readUnsignedInt():Int {
		var uInt = data.getUint32(this.position, littleEndian);
		this.position+=4;
		return uInt;
	}

	public function writeUnsignedInt( value : Int ):Void {
		ensureWrite(this.position + 4);

		data.setUint32(this.position, value, littleEndian);
		this.position += 4;
	}

#if format
	public function uncompress() {
		var bytes = haxe.io.Bytes.ofData(cast byteView);
		var buf = format.tools.Inflate.run(bytes).getData();
		this.byteView = untyped __new__("Uint8Array", buf);

		this.data = untyped __new__("DataView", byteView.buffer);
		this.length = byteView.buffer.byteLength;
	}
#end

	public function jeashGetEndian() : String {
		return (littleEndian == true) ? Endian.LITTLE_ENDIAN : Endian.BIG_ENDIAN;
	}
	public function jeashSetEndian( endian : String ) : String {
		littleEndian = (endian == Endian.LITTLE_ENDIAN);
		return endian;
	}

	public static function jeashOfBuffer(buffer:ArrayBuffer):ByteArray {
		var bytes:ByteArray = new ByteArray();
		bytes.length = buffer.byteLength;
		bytes.data = untyped __new__("DataView", buffer);
		bytes.byteView = untyped __new__("Uint8Array", buffer);
		return bytes;
	}

	public function jeashGetBuffer() { return data.buffer; }
}
