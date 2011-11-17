package format.mp3;
import format.mp3.Data;

/**
 * MPEG Version
 *
 * sored on 2 bits in the file,
 * values represent bit values
 */
class MPEG {
   public static var V1 = 3;
   public static var V2 = 2;
   public static var V25 = 0;
   public static var Reserved = 1;
   
   public static function enum2Num(m : MPEGVersion) : Int {
      return switch(m) {
         case MPEG_V1: V1;
         case MPEG_V2: V2;
         case MPEG_V25: V25;
         case MPEG_Reserved: Reserved;
      }
   }
 
   public static function num2Enum(m : Int) : MPEGVersion {
      return switch(m) {
         case V1: MPEG_V1;
         case V2: MPEG_V2;
         case V25: MPEG_V25;
         default: MPEG_Reserved;
      }
   }

   // V1 Bitrates, can be indexed with [layerIdx][bitrateIdx]
   public static var V1_Bitrates = [
      [ BR_Bad,  BR_Bad,  BR_Bad,  BR_Bad,  BR_Bad,  BR_Bad,  BR_Bad,  BR_Bad,  BR_Bad,  BR_Bad,  BR_Bad,  BR_Bad,  BR_Bad,  BR_Bad,  BR_Bad, BR_Bad], // reserved
      [  BR_Free,  BR_32,  BR_40,  BR_48,  BR_56,  BR_64,  BR_80,  BR_96, BR_112, BR_128, BR_160, BR_192, BR_224, BR_256, BR_320, BR_Bad], // layer III
      [  BR_Free,  BR_32,  BR_48,  BR_56,  BR_64,  BR_80,  BR_96, BR_112, BR_128, BR_160, BR_192, BR_224, BR_256, BR_320, BR_384, BR_Bad], // layer II
      [  BR_Free,  BR_32,  BR_64,  BR_96, BR_128, BR_160, BR_192, BR_224, BR_256, BR_288, BR_320, BR_352, BR_384, BR_416, BR_448, BR_Bad]  // layer I
   ];

   // V2 & V2.5
   public static var V2_Bitrates = [
      [ BR_Bad,  BR_Bad,  BR_Bad,  BR_Bad,  BR_Bad,  BR_Bad,  BR_Bad,  BR_Bad,  BR_Bad,  BR_Bad,  BR_Bad,  BR_Bad,  BR_Bad,  BR_Bad,  BR_Bad, BR_Bad], // reserved
      [  BR_Free,   BR_8,  BR_16,  BR_24,  BR_32,  BR_40,  BR_48,  BR_56,  BR_64,  BR_80,  BR_96, BR_112, BR_128, BR_144, BR_160, BR_Bad], // layer III
      [  BR_Free,   BR_8,  BR_16,  BR_24,  BR_32,  BR_40,  BR_48,  BR_56,  BR_64,  BR_80,  BR_96, BR_112, BR_128, BR_144, BR_160, BR_Bad], // layer II
      [  BR_Free,  BR_32,  BR_48,  BR_56,  BR_64,  BR_80,  BR_96, BR_112, BR_128, BR_144, BR_160, BR_176, BR_192, BR_224, BR_256, BR_Bad]  // layer I
   ];
   
   // index row with V1|V2|V25, column with samplingRateIdx to get sampling rate
   public static var SamplingRates = [
      [SR_11025,  SR_12000,    SR_8000,  SR_Bad],   // V2.5
      [SR_Bad,    SR_Bad,      SR_Bad,   SR_Bad], // dummy
      [SR_22050,  SR_24000,   SR_12000,  SR_Bad],   // V2
      [SR_44100,  SR_48000,   SR_32000,  SR_Bad],   // V1
   ];

   public static function srNum2Enum(sr : Int) : SamplingRate {
      return switch(sr) {
         case  8000:  SR_8000;
         case 11025: SR_11025;
         case 12000: SR_12000;
         case 22050: SR_22050;
         case 24000: SR_24000;
         case 32000: SR_32000;
         case 44100: SR_44100;
         case 48000: SR_48000;
         default: SR_Bad;
      }
   }
 
   public static function srEnum2Num(sr : SamplingRate) : Int {
      return switch(sr) {
         case  SR_8000:  8000;
         case SR_11025: 11025;
         case SR_12000: 12000;
         case SR_22050: 22050;
         case SR_24000: 24000;
         case SR_32000: 32000;
         case SR_44100: 44100;
         case SR_48000: 48000;
         case SR_Bad: -1;
      }
   }


   public static function getBitrateIdx(br : Bitrate, mpeg : MPEGVersion, layer : Layer) : Int {
      var arr = ((mpeg == MPEG_V1) ? V1_Bitrates : V2_Bitrates)[CLayer.enum2Num(layer)];
      for (i in 0...16)
         if (arr[i] == br)
            return i;
      throw "Bitrate index not found";
      // return 15;
   }

   public static function getSamplingRateIdx(sr : SamplingRate, mpeg : MPEGVersion) : Int {
      var arr = SamplingRates[enum2Num(mpeg)];
      for (i in 0...4)
         if (arr[i] == sr)
            return i;
      throw "Sampling rate index not found";
      // return 3;
   }

   public static function bitrateEnum2Num(br : Bitrate) : Int {
      return switch (br) {
         case BR_Bad: -1;
         case BR_Free: 0;
         case BR_8: 8;
         case BR_16: 16;
         case BR_24: 24;
         case BR_32: 32;
         case BR_40: 40;
         case BR_48: 48;
         case BR_56: 56;
         case BR_64: 64;
         case BR_80: 80;
         case BR_96: 96;
         case BR_112: 112;
         case BR_128: 128;
         case BR_144: 144;
         case BR_160: 160;
         case BR_176: 176;
         case BR_192: 192;
         case BR_224: 224;
         case BR_256: 256;
         case BR_288: 288;
         case BR_320: 320;
         case BR_352: 352;
         case BR_384: 384;
         case BR_416: 416;
         case BR_448: 448;
      }
   }

   public static function bitrateNum2Enum(br : Int) : Bitrate {
      return switch(br) {
         case 0: BR_Free;
         case 8: BR_8;
         case 16: BR_16;
         case 24: BR_24;
         case 32: BR_32;
         case 40: BR_40;
         case 48: BR_48;
         case 56: BR_56;
         case 64: BR_64;
         case 80: BR_80;
         case 96: BR_96;
         case 112: BR_112;
         case 128: BR_128;
         case 144: BR_144;
         case 160: BR_160;
         case 176: BR_176;
         case 192: BR_192;
         case 224: BR_224;
         case 256: BR_256;
         case 288: BR_288;
         case 320: BR_320;
         case 352: BR_352;
         case 384: BR_384;
         case 416: BR_416;
         case 448: BR_448;
         default: BR_Bad;
      }
   }

}


/**
 * Layer
 *
 * stored on 2 bits in the file,
 * values represent bit values
 */
class CLayer {
   public static var LReserved = 0;
   public static var LLayer3 = 1;
   public static var LLayer2 = 2;
   public static var LLayer1 = 3;

   public static function enum2Num(l : Layer) : Int {
      return switch(l) {
         case Layer3: LLayer3;
         case Layer2: LLayer2;
         case Layer1: LLayer1;
         case LayerReserved: LReserved;
      }
   }
 
   public static function num2Enum(l : Int) : Layer {
      return switch(l) {
         case LLayer3: Layer3;
         case LLayer2: Layer2;
         case LLayer1: Layer1;
         default: LayerReserved;
      }
   }

}

/**
 * Sound channel mode
 *
 * stored on 2 bits in the file,
 * values represent bit values
 */
class CChannelMode {
   public static inline var CStereo = 0;
   public static inline var CJointStereo = 1;
   public static var CDualChannel = 2;
   public static var CMono = 3;

   public static function enum2Num(c : ChannelMode) : Int {
      return switch(c) {
         case Stereo: CStereo;
         case JointStereo: CJointStereo;
         case DualChannel: CDualChannel;
         case Mono: CMono;
      }
   }
  
  public static function num2Enum(c : Int) : ChannelMode {
      return switch(c) {
         case CStereo: Stereo;
         case CJointStereo: JointStereo;
         case CDualChannel: DualChannel;
         case CMono: Mono;
      }
   }
}

/**
 * Emphasis
 *
 * 2 bits
 */
class CEmphasis {
   public static inline var ENone = 0;
   public static inline var EMs50_15 = 1;
   public static inline var EReserved = 2;
   public static inline var ECCIT_J17 = 3;
   
   public static function enum2Num(c : Emphasis) : Int {
      return switch(c) {
         case NoEmphasis: ENone;
         case Ms50_15: EMs50_15;
         case CCIT_J17: ECCIT_J17;
         case InvalidEmphasis: EReserved;
      }
   } 
   
   public static function num2Enum(c : Int) : Emphasis {
      return switch(c) {
         case ENone: NoEmphasis;
         case EMs50_15: Ms50_15;
         case ECCIT_J17: CCIT_J17;
         case EReserved: InvalidEmphasis;
      }
   }

}



