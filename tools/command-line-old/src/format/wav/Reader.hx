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

class Reader {

	var i : haxe.io.Input;
	var version : Int;

	public function new(i) {
		this.i = i;
		i.bigEndian = false;
	}

	public function read() : WAVE {

		if (i.readString(4) != "RIFF")
			throw "RIFF header expected";

		var len = Int32.toInt(i.readInt32());

		if (i.readString(4) != "WAVE")
			throw "WAVE signature not found";

		//
		// fmt
		//
		if (i.readString(4) != "fmt ")
			throw "expected fmt subchunk";

		var fmtlen = Int32.toInt(i.readInt32());
		
		var format = switch (i.readUInt16()) {
			case 1: WF_PCM;
			default: throw "only PCM (uncompressed) WAV files are supported";
		}
		var channels = i.readUInt16();
		var samplingRate = Int32.toInt(i.readInt32());
		var byteRate = Int32.toInt(i.readInt32());
		var blockAlign = i.readUInt16();
		var bitsPerSample = i.readUInt16();
		
		var nextChunk = i.readString (4);
		
		//
		// cue
		//
		if (nextChunk == "cue ") {
			
			// ignore the cue chunk, if present before the data chunk
			
			var cuelen = Int32.toInt (i.readInt32 ());
			var cues = i.read (cuelen);
			nextChunk = i.readString (4);
			
		}
		
		//
		// data
		//
		if (nextChunk != "data")
			throw "expected data subchunk";
		
		var datalen = Int32.toInt(i.readInt32());
		var data = i.read(datalen);

		return {
			header: {
				format: format,
				channels: channels,
				samplingRate: samplingRate,
				byteRate: byteRate,
				blockAlign: blockAlign,
				bitsPerSample: bitsPerSample
			},
			data: data
		}
	}

}
