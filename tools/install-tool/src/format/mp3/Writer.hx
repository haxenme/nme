/*
 * format - haXe File Formats
 *
 *  MP3 File Format
 *  Copyright (C) 2009 Robin Palotai
 *
 * Copyright (c) 2009, The haXe Project Contributors
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

package format.mp3;
import format.mp3.Data;
import format.mp3.Constants;

class Writer {

   public static inline var WRITE_ID3V2 = true;
   public static inline var DONT_WRITE_ID3V2 = false;

   var o : haxe.io.Output;
   var bits : format.tools.BitsOutput;

   public function new(output : haxe.io.Output) {
      o = output;
      o.bigEndian = true;
      bits = new format.tools.BitsOutput(o);
   }

   /**
    * Pass DONT_WRITE_ID3V2 (false) as second parameter to
    * write the mpeg stream without id3v2
    */
   public function write(mp3 : MP3, writeId3v2 = true) {
      if (writeId3v2 && mp3.id3v2 != null)
         writeID3v2(mp3.id3v2);

      for (f in mp3.frames)
         writeFrame(f);
   }

   public function writeID3v2(id3v2 : ID3v2Info) {
      o.writeString('ID3');
      o.writeUInt16(id3v2.versionBytes);
      o.writeByte(id3v2.flagByte);

      var arr = new Array<Int>();
      var l = id3v2.data.length;
      for (i in 0...4) {
         arr.push(l & 0x7f);
         l >>= 7;
      }
      for (i in 0...4) {
         bits.writeBit(false);
         bits.writeBits(7, arr[3-i]);
      }
      bits.flush();

      o.write(id3v2.data);
   }

   public function writeFrame(f : MP3Frame) {
      // 11bit syncword
      o.writeByte(0xFF); // byte boundary
      bits.writeBits(3, 7);
      
      var h = f.header;
      bits.writeBits(2, MPEG.enum2Num(h.version));
      bits.writeBits(2, CLayer.enum2Num(h.layer));
      bits.writeBit(!h.hasCrc);  // byte boundary

      bits.writeBits(4, MPEG.getBitrateIdx(h.bitrate, h.version, h.layer));
      bits.writeBits(2, MPEG.getSamplingRateIdx(h.samplingRate, h.version));
      bits.writeBit(h.isPadded);

      // private bit (free use)
      bits.writeBit(h.privateBit);  // byte boundary

      bits.writeBits(2, CChannelMode.enum2Num(h.channelMode));
      bits.writeBit(h.isIntensityStereo);
      bits.writeBit(h.isMSStereo);

      bits.writeBit(h.isCopyrighted);
      bits.writeBit(h.isOriginal);
      bits.writeBits(2, CEmphasis.enum2Num(h.emphasis)); // byte boundary

      bits.flush();

      if (h.hasCrc) {
         o.writeUInt16(h.crc16);
      }

      o.write(f.data);
   }
}
