/*
 * format - haXe File Formats
 *
 *  WAVE File Format
 *  Copyright (C) 2009 Robin Palotai
 *
 * Copyright (c) 2009, The haXe Project Contributors
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *	- Redistributions of source code must retain the above copyright
 *	  notice, this list of conditions and the following disclaimer.
 *	- Redistributions in binary form must reproduce the above copyright
 *	  notice, this list of conditions and the following disclaimer in the
 *	  documentation and/or other materials provided with the distribution.
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

package format.wav;
import format.wav.Data;
import haxe.Int32;

class Writer {

	var o : haxe.io.Output;

	public function new(output : haxe.io.Output) {
		o = output;
		o.bigEndian = false;
	}

	public function write(wav : WAVE) {
		var hdr = wav.header;

		o.writeString("RIFF");
		o.writeInt32(Int32.ofInt(36 + wav.data.length));
		o.writeString("WAVE");

		o.writeString("fmt ");
		o.writeInt32(Int32.ofInt(16));
		o.writeUInt16(1);
		o.writeUInt16(hdr.channels);
		o.writeInt32(Int32.ofInt(hdr.samplingRate));
		o.writeInt32(Int32.ofInt(hdr.byteRate));
		o.writeUInt16(hdr.blockAlign);
		o.writeUInt16(hdr.bitsPerSample);

		o.writeString("data");
		o.writeInt32(Int32.ofInt(wav.data.length));
		o.write(wav.data);
	}

}
