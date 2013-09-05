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

class BitsInput {

	var i : haxe.io.Input;
	var nbits : Int;
	var bits : Int;

	public function new(i) {
		this.i = i;
		nbits = 0;
		bits = 0;
	}

	public function readBits(n) {
		if( nbits >= n ) {
			var c = nbits - n;
			var k = (bits >>> c) & ((1 << n) - 1);
			nbits = c;
			return k;
		}
		var k = i.readByte();
		if( nbits >= 24 ) {
			if( n >= 31 ) throw "Bits error";
			var c = 8 + nbits - n;
			var d = bits & ((1 << nbits) - 1);
			d = (d << (8 - c)) | (k << c);
			bits = k;
			nbits = c;
			return d;
		}
		bits = (bits << 8) | k;
		nbits += 8;
		return readBits(n);
	}

	public function read() {
		if( nbits == 0 ) {
			bits = i.readByte();
			nbits = 8;
		}
		nbits--;
		return ((bits >>> nbits) & 1) == 1;
	}

	public inline function reset() {
		nbits = 0;
	}

}

