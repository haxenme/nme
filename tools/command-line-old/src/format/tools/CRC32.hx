/*
 * format - haXe File Formats
 *
 * Copyright (c) 2008, The haXe Project Contributors
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
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
package format.tools;
import haxe.Int32;

class CRC32 {

	static inline var POLYNOM = Int32.make(0xEDB8, 0x8320);
	var crc : haxe.Int32;

	public function new() {
		crc = Int32.make(0xFFFF,0xFFFF);
	}

	inline function i32(i:Int) : Int32 {
		#if neko
		return cast i;
		#else
		return Int32.ofInt(i);
		#end
	}

	public function run( b : haxe.io.Bytes ) {
		var crc = crc;
		var polynom = POLYNOM;
		for( i in 0...b.length ) {
			var tmp = Int32.and( Int32.xor(crc,i32(b.get(i))), i32(0xFF) );
			for( j in 0...8 ) {
				if( Int32.and(tmp,i32(1)) == i32(1) )
					tmp = Int32.xor(Int32.ushr(tmp,1),polynom);
				else
					tmp = Int32.ushr(tmp,1);
			}
			crc = Int32.xor(Int32.ushr(crc,8), tmp);
		}
		this.crc = crc;
	}

	public function byte( b : Int ) {
		var polynom = POLYNOM;
		var tmp = Int32.and( Int32.xor(crc,i32(b)), i32(0xFF) );
		for( j in 0...8 ) {
			if( Int32.and(tmp,i32(1)) == i32(1) )
				tmp = Int32.xor(Int32.ushr(tmp,1),polynom);
			else
				tmp = Int32.ushr(tmp,1);
		}
		crc = Int32.xor(Int32.ushr(crc,8), tmp);
	}

	public function get() {
		return Int32.xor(crc, Int32.make(0xFFFF,0xFFFF));
	}

	/*
	 *  Function computes CRC32 code of a given string.
	 *  Warning: returns Int32 as result uses all 32 bits
	 *  UTF - 8 coding is not supported
	 */
	public static function encode( b : haxe.io.Bytes ) : Int32 {
		var c = new CRC32();
		c.run(b);
		return c.get();
	}
}
