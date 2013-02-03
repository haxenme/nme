/*
 * format - haXe File Formats
 *
 *  SWF File Format
 *  Copyright (C) 2004-2008 Nicolas Cannasse
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
package format.swf;

/**
 * Tag id constants
 * not for public usage
 */
class TagId {
   public static inline var End = 0x00;
   public static inline var ShowFrame = 0x01;
   public static inline var DefineShape = 0x02;
   public static inline var PlaceObject = 0x04;
   public static inline var RemoveObject = 0x05;
   public static inline var DefineBits = 0x06;
   public static inline var DefineButton = 0x07;
   public static inline var JPEGTables = 0x08;
   public static inline var SetBackgroundColor= 0x09;
   public static inline var DefineFont = 0x0A;
   public static inline var DefineText = 0x0B;
   public static inline var DoAction = 0x0C;
   public static inline var DefineFontInfo = 0x0D;
   public static inline var DefineSound = 0x0E;
   public static inline var StartSound = 0x0F;
   public static inline var DefineButtonSound = 0x11;
   public static inline var SoundStreamHead = 0x12;
   public static inline var SoundStreamBlock = 0x13;
   public static inline var DefineBitsLossless = 0x14;
   public static inline var DefineBitsJPEG2 = 0x15;
   public static inline var DefineShape2 = 0x16;
   public static inline var DefineButtonCxform = 0x17;
   public static inline var Protect = 0x18;
   public static inline var PlaceObject2 = 0x1A;
   public static inline var RemoveObject2= 0x1C;
   public static inline var DefineShape3 = 0x20;
   public static inline var DefineText2 = 0x21;
   public static inline var DefineButton2 = 0x22;
   public static inline var DefineBitsJPEG3 = 0x23;
   public static inline var DefineBitsLossless2= 0x24;
   public static inline var DefineEditText = 0x25;
   public static inline var DefineSprite = 0x27;
   public static inline var FrameLabel= 0x2B;
   public static inline var SoundStreamHead2 = 0x2D;
   public static inline var DefineMorphShape = 0x2E;
   public static inline var DefineFont2 = 0x30;
   public static inline var ExportAssets = 0x38;
   public static inline var ImportAssets= 0x39;
   public static inline var EnableDebugger = 0x3A;
   public static inline var DoInitAction = 0x3B;
   public static inline var DefineVideoStream = 0x3C;
   public static inline var VideoFrame = 0x3D;
   public static inline var DefineFontInfo2 = 0x3E;
   public static inline var EnableDebugger2 = 0x40;
   public static inline var ScriptLimits = 0x41;
   public static inline var SetTabIndex = 0x42;
   public static inline var FileAttributes = 0x45;
   public static inline var PlaceObject3 = 0x46;
   public static inline var ImportAssets2 = 0x47;
   public static inline var RawABC = 0x48;
   public static inline var DefineFontAlignZones= 0x49;
   public static inline var CSMTextSettings = 0x4A;
   public static inline var DefineFont3= 0x4B;
   public static inline var SymbolClass = 0x4C;
   public static inline var Metadata = 0x4D;
   public static inline var DefineScalingGrid = 0x4E;
   public static inline var DoABC = 0x52;
   public static inline var DefineShape4 = 0x53;
   public static inline var DefineMorphShape2 = 0x54;
   public static inline var DefineSceneAndFrameLabelData = 0x56;
   public static inline var DefineBinaryData = 0x57;
   public static inline var DefineFontName = 0x58;
   public static inline var StartSound2 = 0x59;
   public static inline var DefineBitsJPEG4 = 0x5A;
   public static inline var DefineFont4 = 0x5B;
}

class FillStyleTypeId {
   public static inline var Solid = 0x00;
   public static inline var LinearGradient = 0x10;
   public static inline var RadialGradient = 0x12;
   public static inline var FocalRadialGradient = 0x13;
   public static inline var RepeatingBitmap = 0x40;
   public static inline var ClippedBitmap = 0x41;
   public static inline var NonSmoothedRepeatingBitmap = 0x42;
   public static inline var NonSmoothedClippedBitmap = 0x43;
}

