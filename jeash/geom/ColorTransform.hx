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

package jeash.geom;

class ColorTransform
{
   public var alphaMultiplier : Float;
   public var alphaOffset : Float;
   public var blueMultiplier : Float;
   public var blueOffset : Float;
   public var color (jeashGetColor, jeashSetColor) : Int;
   public var greenMultiplier : Float;
   public var greenOffset : Float;
   public var redMultiplier : Float;
   public var redOffset : Float;

   public function new(
      ?inRedMultiplier : Float,
      ?inGreenMultiplier : Float,
      ?inBlueMultiplier : Float,
      ?inAlphaMultiplier : Float,
      ?inRedOffset : Float,
      ?inGreenOffset : Float,
      ?inBlueOffset : Float,
      ?inAlphaOffset : Float) : Void
   {
      redMultiplier = inRedMultiplier==null ? 1.0 : inRedMultiplier;
      greenMultiplier = inGreenMultiplier==null ? 1.0 : inGreenMultiplier;
      blueMultiplier = inBlueMultiplier==null ? 1.0 : inBlueMultiplier;
      alphaMultiplier = inAlphaMultiplier==null ? 1.0 : inAlphaMultiplier;
      redOffset = inRedOffset==null ? 0.0 : inRedOffset;
      greenOffset = inGreenOffset==null ? 0.0 : inGreenOffset;
      blueOffset = inBlueOffset==null ? 0.0 : inBlueOffset;
      alphaOffset = inAlphaOffset==null ? 0.0 : inAlphaOffset;
   }

   public function concat(second : jeash.geom.ColorTransform) : Void {
      redMultiplier += second.redMultiplier;
	  greenMultiplier += second.greenMultiplier;
	  blueMultiplier += second.blueMultiplier;
	  alphaMultiplier += second.alphaMultiplier;
   }

	private function jeashGetColor():Int {
		return ((Std.int (redOffset) << 16) | (Std.int (greenOffset) << 8) | Std.int (blueOffset));
	}

	private function jeashSetColor(value:Int):Int {
      redOffset = (value >> 16) & 0xFF;
		greenOffset = (value >> 8) & 0xFF;
		blueOffset = value & 0xFF;
		
		redMultiplier = 0;
		greenMultiplier = 0;
		blueMultiplier = 0;
		
		return color;
	}
}