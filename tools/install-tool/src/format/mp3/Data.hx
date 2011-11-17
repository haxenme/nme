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

typedef MP3 = {
   // ID3v2 tag payload (raw), if found at the beginning of the file,
   // null otherwise.
   // 
   // This should be parsed externally if required
   var id3v2 : ID3v2Info;
   
   // valid frames read (others were discarded)
   var frames : Array<MP3Frame>;

   // sum count of samples found inside the valid frames
   var sampleCount : Int;

   // sum length of all frame data (excluding the 4-byte headers and 2-byte CRC-s if present)
   var sampleSize : Int;
}

typedef ID3v2Info = {
   var versionBytes : Int;    // the 2 version bytes
   var flagByte : Int;
   var data : haxe.io.Bytes;
}

typedef MP3Frame = {
	var header : MP3Header;
	var data : haxe.io.Bytes;
}

typedef MP3Header = {
   public var version : MPEGVersion;  
   public var layer : Layer;

   public var hasCrc : Bool;
   public var crc16 : Int;

   public var bitrate : Bitrate;

   public var samplingRate : SamplingRate;

   public var isPadded : Bool;
   public var privateBit : Bool;

   public var channelMode : ChannelMode;
   public var isIntensityStereo : Bool;
   public var isMSStereo : Bool;

   public var isCopyrighted : Bool;

   public var isOriginal : Bool;

   public var emphasis : Emphasis;
}

enum MPEGVersion {
   MPEG_V1;
   MPEG_V2;
   MPEG_V25;
   MPEG_Reserved;
}

enum Bitrate {
   BR_8;
   BR_16;
   BR_24;
   BR_32;
   BR_40;
   BR_48;
   BR_56;
   BR_64;
   BR_80;
   BR_96;
   BR_112;
   BR_128;
   BR_144;
   BR_160;
   BR_176;
   BR_192;
   BR_224;
   BR_256;
   BR_288;
   BR_320;
   BR_352;
   BR_384;
   BR_416;
   BR_448;
   BR_Free;
   BR_Bad;
}

enum SamplingRate {
   SR_8000;
   SR_11025;
   SR_12000;
   SR_22050;
   SR_24000;
   SR_32000;
   SR_44100;
   SR_48000;
   SR_Bad;
}

enum Layer {
   LayerReserved;
   Layer3;
   Layer2;
   Layer1;
}

enum ChannelMode {
   Stereo;
   JointStereo;
   DualChannel;
   Mono;
}

enum Emphasis {
   NoEmphasis;
   Ms50_15;
   CCIT_J17;
   InvalidEmphasis;
}

