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

class Tools {

    /**
    * Returns kbps
    */
   public static function getBitrate(mpegVersion : Int, layerIdx : Int, bitrateIdx : Int) : Bitrate {
      if (mpegVersion == MPEG.Reserved || layerIdx == CLayer.LReserved)
         return BR_Bad;

      return (mpegVersion == MPEG.V1 ? MPEG.V1_Bitrates : MPEG.V2_Bitrates)[layerIdx][bitrateIdx];
   }
   
   /**
    * Returns Hz
    */
   public static function getSamplingRate(mpegVersion : Int, samplingRateIdx : Int) : SamplingRate {
      return MPEG.SamplingRates[mpegVersion][samplingRateIdx];
   }

   /**
    * Tells whether the header is invalid.
    */
   public static function isInvalidFrameHeader(hdr : MP3Header) {
      return
         hdr.version == MPEG_Reserved
         || hdr.layer == LayerReserved
         || hdr.bitrate == BR_Bad
         || hdr.bitrate == BR_Free  // free rate (not necessary bad, but would need effort to handle)
         || hdr.samplingRate == SR_Bad  
         ;
   }

   /**
    * Return sample data size. Note that
    * the 4 bytes subtracted is the size of the header,
    * so this 4 bytes less the frame size.
    *
    * Also, 2 bytes are subtracted for CRC too, if present
    */
   public static function getSampleDataSize(mpegVersion : Int, bitrate : Int, samplingRate : Int, isPadded : Bool, hasCrc : Bool) : Int {
      return Std.int(((mpegVersion == MPEG.V1 ? 144 : 72) * bitrate*1000) / samplingRate) + (isPadded ? 1 : 0) - (hasCrc ? 2 : 0) - 4;
   }

   public static function getSampleDataSizeHdr(hdr : MP3Header) : Int {
      return getSampleDataSize(
         MPEG.enum2Num(hdr.version),
         MPEG.bitrateEnum2Num(hdr.bitrate),
         MPEG.srEnum2Num(hdr.samplingRate), 
         hdr.isPadded, hdr.hasCrc);
   }

   /**
    * Returns the number of samples in the frame.
    */
   public static function getSampleCount(mpegVersion : Int) : Int {
      // this is fixed in the standard
      return mpegVersion == MPEG.V1 ? 1152 : 576;
   }

   public static function getSampleCountHdr(hdr : MP3Header) : Int {
      return getSampleCount(MPEG.enum2Num(hdr.version));
   }

   /**
    * Displays frame info in human-readable format.
    * Subject to change, do not use for programmatical parsing!
    */
   public static function getFrameInfo(fr : MP3Frame) : String {
      return
         Std.string(fr.header.version) + ", " +
         Std.string(fr.header.layer) + ", " +
         Std.string(fr.header.channelMode) + ", " + 
         fr.header.samplingRate + " Hz, " +
         fr.header.bitrate + " kbps " +
         "Emphasis: " + Std.string(fr.header.emphasis) + ", " +
         (fr.header.hasCrc ? "(CRC) " : "") +
         (fr.header.isPadded ? "(Padded) " : "") +
         (fr.header.isIntensityStereo ? "(Intensity Stereo) " : "") +
         (fr.header.isMSStereo ? "(MS Stereo) " : "") +
         (fr.header.isCopyrighted ? "(Copyrighted) " : "") +
         (fr.header.isOriginal ? "(Original) " : "");
   }
} 
