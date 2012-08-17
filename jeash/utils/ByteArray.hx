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

class ByteArray {

	var data : DataView;
	var byteView : Uint8Array;
	var bigEndian : Bool;

	public var bytesAvailable(jeashGetBytesAvailable,null) : Int;
	public var endian(jeashGetEndian,jeashSetEndian) : Endian;
	public var objectEncoding : Int;

	public var position : Int;
	public var length : Int;

	static inline var BYTE_ARRAY_BUFFER_SIZE = 8192;

	function jeashGetBytesAvailable():Int return length - position

	function readFullBytes( bytes : Bytes, pos : Int, len : Int ) {
		for ( i in pos...pos+len )
			data.setInt8(this.position++, bytes.get(i));
	}

	public function new(len:Int = BYTE_ARRAY_BUFFER_SIZE) {
	
		this.position = 0;
		this.length = len;

		var buffer = untyped __new__("ArrayBuffer", len);
		this.data = untyped __new__("DataView", buffer);
		this.byteView = untyped __new__("Uint8Array", buffer);

		this.bigEndian = false;
	}

	function jeashResizeBuffer(len:Int) {
		var initLength = byteView.length;
		var resized:Uint8Array = untyped __new__("Uint8Array", len);

		resized.set(byteView);

		this.data = untyped __new__("DataView", resized.buffer);
		this.byteView = resized;
	}

	public function readByte() : Int {
		return data.getUint8(this.position++);
	}

	public function readBytes(bytes : ByteArray, ?offset : UInt, ?length : UInt) {
		if(offset < 0 || length < 0)
			throw new IOError("Read error - Out of bounds");

		if (offset == null) offset = 0;
		if (length == null) length = this.length;

		if(bytes.byteView.length < length + offset) {
			bytes.jeashResizeBuffer(offset+length);
		}

		bytes.byteView.set(byteView.subarray(this.position, this.position+length), offset);
		bytes.position = offset;

		this.position += length;
		if (bytes.position+length > bytes.length) bytes.length = bytes.position+length;
	}
	
	public function writeByte(value : Int) {
		if( this.position+1 >= byteView.length )
			jeashResizeBuffer(this.position+1);
		data.setInt8(this.position++, value);
		if (this.position > length) {
			length++;
		}
	}

	public function writeBytes(bytes : ByteArray, ?offset : UInt, ?length : UInt) {
		if(offset < 0 || length < 0) 
			throw new IOError("Write error - Out of bounds");

		if(byteView.length < length + this.position) {
			jeashResizeBuffer(this.position+length);
		}

		bytes.position = offset+length;

		byteView.set(bytes.byteView.subarray(offset, offset+length), this.position);
		this.position += length;
		if (this.position > this.length) this.length = this.position;
	}

	public function readBoolean() {
		return this.readByte() == 1 ? true : false;
	}

	public function writeBoolean(value : Bool) {
		this.writeByte(value?1:0);
	}

	public function readDouble() : Float {
		var double = data.getFloat64(this.position, !bigEndian);
		this.position += 8;
		return double;
	}

	public function writeDouble(x : Float) {
		if( this.position+8 >= byteView.length )
			jeashResizeBuffer(this.position+8);
		data.setFloat64(this.position, x, !bigEndian);
		this.position += 8;
		if (this.position > this.length) this.length = this.position;
	}

	public function readFloat() : Float {
		var float = data.getFloat32(this.position, !bigEndian);
		this.position += 4;
		return float;
	}

	public function writeFloat( x : Float ) {
		if( this.position+4 >= byteView.length )
			jeashResizeBuffer(this.position+4);
		data.setFloat32(this.position, x, !bigEndian);
		this.position += 4;
		if (this.position > this.length) this.length = this.position;
	}

	public function readInt() {
		var int = data.getInt32(this.position, !bigEndian);
		this.position += 4;
		return int;
	}

	public function writeInt(value : Int) {
		if( this.position+4 >= byteView.length )
			jeashResizeBuffer(this.position+4);
		data.setInt32(this.position, value, !bigEndian);
		this.position += 4;
		if (this.position > this.length) this.length = this.position;
	}

	public function readShort() {
		var short = data.getInt16(this.position, !bigEndian);
		this.position += 2;
		return short;
	}

	public function writeShort(value : Int) {
		if( this.position+2 >= byteView.length )
			jeashResizeBuffer(this.position+2);
		data.setInt16(this.position, value, !bigEndian);
		this.position += 2;
		if (this.position > this.length) this.length = this.position;
	}

	public function readUnsignedShort():Int {
		var uShort = data.getUint16(this.position, !bigEndian);
		this.position +=2;
		return uShort;
	}

	public function writeUnsignedShort( value : Int ) {
		if( this.position+2 >= byteView.length )
			jeashResizeBuffer(this.position+2);
		data.setUint16(this.position, value, !bigEndian);
		this.position += 2;
		if (this.position > this.length) this.length = this.position;
	}

	public function readUTF() {
		return readUTFBytes(length - this.position);
	}

	public function writeUTF(value : String) {
		writeUTFBytes(value);
	}

	public function writeUTFBytes(value : String) {
		if( this.position+value.length*4 >= byteView.length ) {
			jeashResizeBuffer(this.position+value.length*4);
		}
		// utf8-decode
		for( i in 0...value.length ) {
			var c : Int = StringTools.fastCodeAt(value, i);
			if( c <= 0x7F ) {
				this.data.setUint8(this.position++, c);
			} else if( c <= 0x7FF ) {
				this.data.setUint8(this.position++, 0xC0 | (c >> 6));
				this.data.setUint8(this.position++, 0x80 | (c & 63));
			} else if( c <= 0xFFFF ) {
				this.data.setUint8(this.position++, 0xE0 | (c >> 12));
				this.data.setUint8(this.position++, 0x80 | ((c >> 6) & 63));
				this.data.setUint8(this.position++, 0x80 | (c & 63));
			} else {
				this.data.setUint8(this.position++, 0xF0 | (c >> 18));
				this.data.setUint8(this.position++, 0x80 | ((c >> 12) & 63));
				this.data.setUint8(this.position++, 0x80 | ((c >> 6) & 63));
				this.data.setUint8(this.position++, 0x80 | (c & 63));
			}
		}
		if (this.position > this.length) this.length = this.position;
	}

	public function readUTFBytes(len:Int) {
		var value = "";
		var fcc = String.fromCharCode;
		var max = this.position+len;
		if (max >= byteView.length)
			jeashResizeBuffer(max);
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
		var uInt = data.getUint32(this.position, !bigEndian);
		this.position+=4;
		return uInt;
	}

	public function writeUnsignedInt( value : Int ) {
		if( this.position+4 >= byteView.length )
			jeashResizeBuffer(this.position+4);
		data.setUint32(this.position, value, !bigEndian);
		this.position+=4;
		if (this.position > this.length) this.length = this.position;
	}

#if format
	public function uncompress() {
		var bytes = haxe.io.Bytes.ofData(cast byteView);
		var buf = format.tools.Inflate.run(bytes).getData();
		this.byteView = new Uint8Array(buf);

		this.data = new DataView(byteView.buffer);
		this.length = byteView.buffer.byteLength;
	}
#end

	public function jeashGetEndian() : Endian {
		if ( bigEndian == true ) {
			return Endian.BIG_ENDIAN;
		} else {
			return Endian.LITTLE_ENDIAN;
		}
	}
	public function jeashSetEndian( endian : Endian ) : Endian {
		if ( endian == Endian.BIG_ENDIAN ) {
			bigEndian = true;
		} else {
			bigEndian = false;
		}

		return endian;
	}

	public static function jeashOfBuffer(buffer:ArrayBuffer) {
		var bytes = new ByteArray(buffer.byteLength);
		bytes.data = untyped __new__("DataView", buffer);
		bytes.byteView = untyped __new__("Uint8Array", buffer);
		return bytes;
	}

	public function jeashGetBuffer() return data.buffer
}
