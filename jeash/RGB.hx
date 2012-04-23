/**
 * Copyright (c) 2010, Jeash contributors.
 * 
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
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

package jeash;

#if neko
typedef RGBI32 = haxe.Int32;
import haxe.Int32;
#else
typedef RGBI32 = Int;
#end

class RGB
{
   #if neko
   public static var ZERO : Int32 = Int32.make(0,0);
   public static var ONE : Int32 = Int32.make(0,1);
   public static var RGBMask : Int32 = Int32.make(0xff,0xffff);

   public static var CLEAR : Int32 = Int32.make(0,0);
   public static var BLACK : Int32 = Int32.make(0xff00,0x0000);
   public static var WHITE : Int32 = Int32.make(0xffff,0xffff);
   public static var RED : Int32 = Int32.make(0xffff,0x0000);
   public static var GREEN : Int32 = Int32.make(0xff00,0xff00);
   public static var BLUE : Int32 = Int32.make(0xff00,0x00ff);

   public static function RGB(inR:Int, inG:Int, inB:Int ) : Int32
   {
      return Int32.make(inR, (inG<<8) | inB);
   }
   public static function IRGB(inRGBA:Int32 ) : Int
   {
      return Int32.toInt(Int32.and(inRGBA,RGBMask));
   }

   public static function RGBA(inR:Int, inG:Int, inB:Int, inA:Int=255 ) : Int32
   {
      return Int32.make( (inA<<8) | inR, (inG<<8) | inB);
   }

   public static function Red(inRGBA:Int32) { return (Int32.toInt(inRGBA) >> 16) & 0xff; }
   public static function Green(inRGBA:Int32) { return (Int32.toInt(inRGBA) >> 8) & 0xff; }
   public static function Blue(inRGBA:Int32) { return (Int32.toInt(inRGBA)) & 0xff; }
   public static function Alpha(inRGBA:Int32) { return (Int32.toInt(haxe.Int32.shr(inRGBA,24))) & 0xff; }


   #else
   public static inline var ZERO : Int = 0;
   public static inline var ONE : Int = 1;

   public static var CLEAR = 0x00000000;
   public static var BLACK = 0xff000000;
   public static var WHITE = 0xffffffff;
   public static var RED = 0xffff0000;
   public static var GREEN = 0xff00ff00;
   public static var BLUE = 0xff0000ff;

   public static function RGB(inR:Int, inG:Int, inB:Int ) : Int
   {
      return (inR<<16) | (inG<<8) | inB;
   }

   public static function IRGB(inRGBA:Int ) : Int
   {
      return inRGBA & 0xffffff;
   }

   public static function RGBA(inR:Int, inG:Int, inB:Int, inA:Int=255 ) : Int
   {
      return (inA<<24) | (inR<<16) | (inG<<8) | inB;
   }

   public static function Red(inRGBA:Int) { return (inRGBA >> 16) & 0xff; }
   public static function Green(inRGBA:Int) { return (inRGBA >> 8) & 0xff; }
   public static function Blue(inRGBA:Int) { return inRGBA & 0xff; }
   public static function Alpha(inRGBA:Int) { return (inRGBA>>24) & 0xff; }

   #end
}

