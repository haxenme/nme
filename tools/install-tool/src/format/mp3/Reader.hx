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

/**
 * Used by seekFrame to retrun the type
 * of frame (possibly) found.
 */
enum FrameType {
   FT_MP3; // possible mp3 frame
   FT_NONE;
}

class Reader {

	var i : haxe.io.Input;
	var bits : format.tools.BitsInput;
	var version : Int;

   // number of samples in the (valid) frames
   var samples : Int;
   var sampleSize : Int;

   // Indicates if any bytes were read from the input.
   // Now used in seekFrame() for skipping an ID3v2 tag (supposedly at the beginning of the file).
   var any_read : Bool;

   // Filled by seekframe if encounters an ID3v2 tag
   var id3v2_data : haxe.io.Bytes; // not null if tag found
   var id3v2_version : Int; // the two version bytes
   var id3v2_flags : Int; // one byte of flags

	public function new(i) {
		this.i = i;
      i.bigEndian = true;
		bits = new format.tools.BitsInput(i);

      samples = 0;
      sampleSize = 0;
      any_read = false;
	}

   /**
    * Called after found 'ID3' signature
    * at the beginning of the file.
    *
    * Records the raw tag data.
    */
   public function skipID3v2() {
      id3v2_version = i.readUInt16();
      id3v2_flags = i.readByte();

      // to read the size of the flag excluding the header, 
      // we have to read 4x 7bits, each by reading a byte and 
      // ignoring the MSB
      //
      // (however the MSB should already be 0)
      var size = i.readByte() & 0x7F;
      size = (size << 7) | (i.readByte() & 0x7f);
      size = (size << 7) | (i.readByte() & 0x7f);
      size = (size << 7) | (i.readByte() & 0x7f);

      id3v2_data = i.read(size);
   }

   /**
    * Winds the input stream until the 11-bit
    * syncword is found.
    *
    * @returns Bool false if not found (this should happen at eof).
    */
   public function seekFrame() : FrameType {
      var found = false;
      try {
         var b : Int;

         while (true) {
            #if DDEBUG neko.Lib.print('s'); #end
            b = i.readByte();
            if (!any_read) {
               any_read = true;

               // check for "ID3": 0x49 0x44 0x33
               if (b == 0x49) {
                  b = i.readByte();
                  if (b == 0x44) {
                     b = i.readByte();
                     if (b == 0x33) {
                        // Found the ID3 tag
                        // this was not a full check according to the
                        // standard, but is quite safe to assume

                        #if DDEBUG neko.Lib.print('i'); #end
                        skipID3v2();
                     }
                  }
               }
            }

            if (b == 255) {
               #if DDEBUG neko.Lib.print('S'); #end
               bits.reset();
               b = bits.readBits(3);
               if (b == 7) {
                  #if DDEBUG neko.Lib.print('M'); #end
                  return FT_MP3;
               }
            }
         }
         return FT_NONE;
      }
      catch (ex : haxe.io.Eof) {
         return FT_NONE;
      }
   }

   /**
    * Returns all valid frames. Invalid frames
    * are discarded.
    */
	public function readFrames() : Array<MP3Frame> {
      var frames = new Array();
      var ft;
      while ((ft = seekFrame()) != FT_NONE) {
         switch (ft) {
            case FT_MP3:
               var f = readFrame();
               if (f != null)
                  frames.push(f);
            
            case FT_NONE:
               // should not happen
         }
      }
      return frames;
   }

   /**
    * Returns null if header proves to be invalid.
    */
   public function readFrameHeader() : MP3Header {

      #if DDEBUG neko.Lib.print('h'); #end

      // continue reading from bit 4 (just after syncword)
      var version = bits.readBits(2);
      var layer = bits.readBits(2);

      var hasCrc = !bits.read(); // prot = false means crc=1
      
      // check validity early before processing next byte
      if (version == MPEG.Reserved || layer == CLayer.LReserved)
         return null;

      #if DDEBUG neko.Lib.print('.'); #end

      var bitrateIdx = bits.readBits(4);
      var bitrate = Tools.getBitrate(version, layer, bitrateIdx);

      var samplingRateIdx = bits.readBits(2);
      var samplingRate = Tools.getSamplingRate(version, samplingRateIdx);

      var isPadded = bits.read();

      // private bit (free use)
      var privateBit = bits.read();

      // check validity again before processing next byte
      if (bitrate == BR_Bad || bitrate == BR_Free || samplingRate == SR_Bad)
         return null;

      #if DDEBUG neko.Lib.print('.'); #end

      var channelMode = bits.readBits(2);
      
      // mode extension bits
      var isIntensityStereo = bits.read();
      var isMSStereo = bits.read();

      var isCopyrighted = bits.read();
      var isOriginal = bits.read();
      var emphasis = bits.readBits(2);

      #if DDEBUG neko.Lib.print('.'); #end

      var crc16 = 0;
      if (hasCrc) {
         crc16 = i.readUInt16();
         #if DDEBUG neko.Lib.print('c'); #end
      }

      return {
         version : MPEG.num2Enum(version),
         layer : CLayer.num2Enum(layer),
         hasCrc : hasCrc,
         
         // check this
         crc16 : crc16,
         
         bitrate : bitrate,
         samplingRate : samplingRate,
         isPadded : isPadded,
         privateBit : privateBit,
         channelMode : CChannelMode.num2Enum(channelMode),
         isIntensityStereo : isIntensityStereo,
         isMSStereo : isMSStereo,
         isCopyrighted : isCopyrighted,
         isOriginal : isOriginal,
         emphasis : CEmphasis.num2Enum(emphasis)
      };
   }

   /**
    * Reads a frame from the input.
    *
    * The input position should already be just past the
    * 11 bit syncword.
    *
    * Returns null if the header is invalid or the frame was incomplete.
    */
   public function readFrame() : MP3Frame {
      var header = readFrameHeader();

      if (header == null || Tools.isInvalidFrameHeader(header))
         return null;
      
      #if DDEBUG
         neko.Lib.print('f[' + Tools.getSampleDataSizeHdr(header) + "]");
      #end

      try {
         var data = i.read(Tools.getSampleDataSizeHdr(header));
         samples += Tools.getSampleCountHdr(header);
         sampleSize += data.length;
         
         return {
            header : header,
            data : data
         };
      }
      catch (e : haxe.io.Eof) {
         return null;
      }  
   }
   
   /**
    * Reads the MP3 data. 
    *
    * Currently returns all valid frames.
    */
   public function read() : MP3 {
      var fs = readFrames();

		return {
			frames : fs,
         sampleCount : samples,
         sampleSize : sampleSize,

         id3v2 : (id3v2_data == null) ? null : {
            versionBytes : id3v2_version,
            flagByte : id3v2_flags,
            data : id3v2_data
         }
		};
	}

}
