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

class ArcFour {

	var s : haxe.io.Bytes;
	var sbase : haxe.io.Bytes;
	var i : Int;
	var j : Int;

	public function new( key : haxe.io.Bytes ) {
		var s = haxe.io.Bytes.alloc(256);
		for( i in 0...256 )
			s.set(i,i);
		var j = 0;
		var klen = key.length;
		for( i in 0...256 ) {
			j = (j + s.get(i) + key.get(i % klen)) & 255;
			var tmp = s.get(i);
			s.set(i,s.get(j));
			s.set(j,tmp);
		}
		sbase = s;
		this.s = sbase.sub(0,256);
		this.i = 0;
		this.j = 0;
	}

	public function reset() {
		this.i = 0;
		this.j = 0;
		this.s.blit(0,sbase,0,256);
	}

	public function run( input : haxe.io.Bytes, ipos : Int, length : Int, output : haxe.io.Bytes, opos : Int ) {
		var i = this.i;
		var j = this.j;
		var s = this.s;
		for( p in 0...length ) {
			i = (i + 1) & 255;
			var a = s.get(i);
			j = (j + a) & 255;
			var b = s.get(j);
			s.set(i,b);
			s.set(j,a);
			output.set(opos + p, input.get(ipos + p) ^ s.get((a+b)&255) );
		}
		this.i = i;
		this.j = j;
	}

}