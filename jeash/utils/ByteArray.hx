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

import Html5Dom;

class ByteArray {

	var data : DataView;
	var byteView : Int8Array;
	var bigEndian : Bool;

	public var bytesAvailable(jeashGetBytesAvailable,null) : Int;
	public var endian(jeashGetEndian,jeashSetEndian) : Endian;
	public var objectEncoding : Int;

	public var position : Int;
	public var length : Int;

	function jeashGetBytesAvailable():Int return length - position

	function readString( len : Int ) : String {
		var bytes = Bytes.alloc(len);
		readFullBytes(bytes,0,len);
		return bytes.toString();
	}

	function readFullBytes( bytes : Bytes, pos : Int, len : Int ) {
		for ( i in pos...pos+len )
			data.setInt8(this.position++, bytes.get(i));
	}

	public function new(len:Int) {
		this.position = 0;
		this.length = len;

		var buffer = new ArrayBuffer(len);
		this.data = new DataView(buffer);
		this.byteView = new Int8Array(buffer);

		this.bigEndian = false;
	}

	public function readByte() : Int {
		if( this.position >= this.length )
			throw new IOError("Read error - Out of bounds");
		return data.getUint8(this.position++);
	}

	public function readBytes(bytes : ByteArray, ?offset : UInt, ?length : UInt) {
		if( offset < 0 || length < 0 || offset + length > this.length )
			throw new IOError("Read error - Out of bounds");

		if( this.length == 0 && length > 0 )
			throw new IOError("Read error - Out of bounds");

		if( this.length < length )
			length = this.length;

		bytes.byteView.set(byteView.subarray(this.position, this.position+length), offset);
		bytes.position = offset;

		this.position += length;
	}
	
	public function writeByte(value : Int) {
		data.setInt8(this.position++, value);
	}

	public function writeBytes(bytes : ByteArray, ?offset : UInt, ?length : UInt) {
		if( offset < 0 || length < 0 || offset + length > bytes.length ) throw new IOError("Write error - Out of bounds");
		bytes.position = offset+length;

		byteView.set(bytes.byteView.subarray(offset, offset+length), this.position);
		this.position += length;
	}

	public function readBoolean() {
		return this.readByte() == 1 ? true : false;
	}

	public function writeBoolean(value : Bool) {
		this.writeByte(value?1:0);
	}

	public function readDouble() : Float {
		if( this.position+8 >= this.length )
			throw new IOError("Read error - Out of bounds");
		return data.getFloat64(this.position += 8, !bigEndian);
	}

	public function writeDouble(x : Float) {
		if( this.position+8 >= this.length )
			throw new IOError("Read error - Out of bounds");
		data.setFloat64(this.position += 8, x, !bigEndian);
	}

	public function readFloat() : Float {
		if( this.position+4 >= this.length )
			throw new IOError("Read error - Out of bounds");
		return data.getFloat32(this.position += 4, !bigEndian);
	}

	public function writeFloat( x : Float ) {
		if( this.position+4 >= this.length )
			throw new IOError("Read error - Out of bounds");
		data.setFloat32(this.position += 4, x, !bigEndian);
	}

	public function readInt() {
		if( this.position+4 >= this.length )
			throw new IOError("Read error - Out of bounds");
		return data.getInt32(this.position += 4, !bigEndian);
	}

	public function writeInt(value : Int) {
		if( this.position+4 >= this.length )
			throw new IOError("Read error - Out of bounds");
		data.setInt32(this.position += 4, value, !bigEndian);
	}

	public function readShort() {
		if( this.position+2 >= this.length )
			throw new IOError("Read error - Out of bounds");
		return data.getInt16(this.position += 2, !bigEndian);
	}

	public function writeShort(value : Int) {
		if( this.position+2 >= this.length )
			throw new IOError("Read error - Out of bounds");
		data.setInt16(this.position += 2, value, !bigEndian);
	}

	public function readUnsignedShort():Int {
		if( this.position+2 >= this.length )
			throw new IOError("Read error - Out of bounds");
		return data.getUint16(this.position +=2, !bigEndian);
	}

	public function writeUnsignedShort( value : Int ) {
		if( this.position+2 >= this.length )
			throw new IOError("Read error - Out of bounds");
		data.setUint16(this.position +=2, value, !bigEndian);
	}

	public function readUTF() {
		return readUTFBytes(length - this.position);
	}

	public function writeUTF(value : String) {
		writeUTFBytes(value);
	}

	public function writeUTFBytes(value : String) {
		// utf8-decode
		for( i in 0...value.length ) {
			var c : Int = StringTools.fastCodeAt(value, i);
			if( c <= 0x7F ) {
				data.setUint8(this.position++, c);
			} else if( c <= 0x7FF ) {
				data.setUint8(this.position++, 0xC0 | (c >> 6));
				data.setUint8(this.position++, 0x80 | (c & 63));
			} else if( c <= 0xFFFF ) {
				data.setUint8(this.position++, 0xE0 | (c >> 12));
				data.setUint8(this.position++, 0x80 | ((c >> 6) & 63));
				data.setUint8(this.position++, 0x80 | (c & 63));
			} else {
				data.setUint8(this.position++, 0xF0 | (c >> 18));
				data.setUint8(this.position++, 0x80 | ((c >> 12) & 63));
				data.setUint8(this.position++, 0x80 | ((c >> 6) & 63));
				data.setUint8(this.position++, 0x80 | (c & 63));
			}
		}
	}

	public function readUTFBytes(len:Int) {
		var value = "";
		var fcc = String.fromCharCode;
		var max = this.position+len;
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
		if( this.position+4 >= this.length )
			throw new IOError("Read error - Out of bounds");
		return data.getUint32(this.position+=4, !bigEndian);
	}

	public function writeUnsignedInt( value : Int ) {
		if( this.position+4 >= this.length )
			throw new IOError("Read error - Out of bounds");
		data.setUint32(this.position+=4, value, !bigEndian);
	}

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

		bytes.data = new DataView(buffer);
		bytes.byteView = new Int8Array(buffer);
		return bytes;
	}

	public function jeashGetBuffer() return data.buffer
}
