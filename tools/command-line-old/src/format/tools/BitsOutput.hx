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

class BitsOutput {

	public var o : haxe.io.Output;
	var nbits : Int;
	var bits : Int;

	public function new(o) {
		this.o = o;
		nbits = 0;
		bits = 0;
	}

	public function writeBits(n: Int, v: Int) {
		// Clear unused bits
		v = v & ((1 << n ) - 1);
		if( n + nbits >= 32 ) {
			if( n >= 31 ) throw "Bits error";
			var n2 = 32 - nbits - 1;
			var n3 = n - n2;
			writeBits(n2,v >>> n3);
			writeBits(n3,v & ((1 << n3) - 1));
			return;
		}
		if( n < 0 ) throw "Bits error";
		//if(n < 31)
		//if( (v < 0 || v > (1 << n) - 1) && n != 31 ) throw "Bits error";
		bits = (bits << n) | v;
		nbits += n;
		while( nbits >= 8 ) {
			nbits -= 8;
			o.writeByte((bits >>> nbits) & 0xFF);
		}
	}

	public function writeBit(flag) {
		bits <<= 1;
		if( flag ) bits |= 1;
		nbits++;
		if( nbits == 8 ) {
			nbits = 0;
			o.writeByte(bits & 0xFF);
		}
	}

	public inline function flush() {
		if( nbits > 0 ) {
			writeBits(8-nbits,0);
			nbits = 0;
		}
	}

}

