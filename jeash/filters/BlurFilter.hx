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

package jeash.filters;

import jeash.display.BitmapData;
import jeash.geom.Rectangle;
import jeash.geom.Point;

#if js
import jeash.Html5Dom;
#end

class BlurFilter extends BitmapFilter {
	var jeashKernel:Vector<Int>;
	var jeashBG:Array<Int>;
	var MAX_BLUR_WIDTH:Int;
	var MAX_BLUR_HEIGHT:Int;

	public function new(?inBlurX : Float, ?inBlurY : Float, ?inQuality : Int) {
		super("BlurFilter");
		blurX = inBlurX==null ? 4.0 : inBlurX;
		blurY = inBlurY==null ? 4.0 : inBlurY;

		MAX_BLUR_WIDTH = Lib.current.stage.stageWidth;
		MAX_BLUR_HEIGHT = Lib.current.stage.stageHeight;

		quality = inQuality==null ? 1 : inQuality;
		var bgColor = Lib.current.stage.backgroundColor;
		jeashBG = [(bgColor & 0xFF0000) >>> 16, (bgColor & 0x00FF00) >>> 8, (bgColor & 0x0000FF)];

	}

	override public function clone() : jeash.filters.BitmapFilter {
		return new BlurFilter(blurX,blurY,quality);
	}

	public function applyFilter(inBitmapData : BitmapData, inRect:Rectangle, inPoint:Point, inBitmapFilter:BitmapFilter):Void {
	}

	override public function jeashPreFilter(surface:HTMLCanvasElement) {
		var ctx: CanvasRenderingContext2D = surface.getContext('2d');
		jeashKernel = new Vector();
		if (surface.width == 0 || surface.height == 0) return;

		// safety catch.
		var width = (surface.width > MAX_BLUR_WIDTH) ? MAX_BLUR_WIDTH : surface.width;
		var height = (surface.height > MAX_BLUR_HEIGHT) ? MAX_BLUR_HEIGHT : surface.height;

		jeashBuildKernel(ctx.getImageData (0, 0, width, height).data, width, height, jeashKernel);
	}

	// Implementation reference: http://www.gamasutra.com/features/20010209/Listing2.cpp
	function jeashBuildKernel(src:CanvasPixelArray, srcW:Int, srcH:Int, dst:Vector<Int>) {
		var i=0, j=0, tot=[], maxW=srcW*4;
		for (y in 0...srcH) {
			for (x in 0...srcW) {
				tot[0]=src[j]; tot[1]=src[j+1]; tot[2]=src[j+2]; tot[3]=src[j+3];

				if (x>0) { tot[0]+=dst[i-4]; tot[1]+=dst[i-3]; tot[2]+=dst[i-2]; tot[3]+=dst[i-1]; }
				if (y>0) { tot[0]+=dst[i-maxW]; tot[1]+=dst[i+1-maxW]; tot[2]+=dst[i+2-maxW]; tot[3]+=dst[i+3-maxW]; }
				if (x>0 && y>0) { tot[0]-=dst[i-maxW-4]; tot[1]-=dst[i-maxW-3]; tot[2]-=dst[i-maxW-2]; tot[3]-=dst[i-maxW-1]; }

				dst[i]=tot[0]; dst[i+1]=tot[1]; dst[i+2]=tot[2]; dst[i+3]=tot[3];

				i+=4; j+=4;
			}
		}
	}

	function jeashBoxBlur(dst:CanvasPixelArray, srcW:Int, srcH:Int, p:Vector<Int>, boxW:Int, boxH:Int) {
		var mul1=1.0/((boxW*2+1)*(boxH*2+1)), i=0, tot=[], h1=0, l1=0, h2=0, l2=0;
		var mul2=1.7/((boxW*2+1)*(boxH*2+1));
		for (y in 0...srcH) {
			for (x in 0...srcW) {
				h1 = if (x+boxW >= srcW) srcW-1; else (x+boxW);
				l1 = if (y+boxH >= srcH) srcH-1; else (y+boxH);
				h2 = if (x-boxW < 0) 0; else (x-boxW);
				l2 = if (y-boxH < 0) 0; else (y-boxH);

				tot[0]=p[(h1+l1*srcW)*4]+p[(h2+l2*srcW)*4]-p[(h2+l1*srcW)*4]-p[(h1+l2*srcW)*4];
				tot[1]=p[(h1+l1*srcW)*4+1]+p[(h2+l2*srcW)*4+1]-p[(h2+l1*srcW)*4+1]-p[(h1+l2*srcW)*4+1];
				tot[2]=p[(h1+l1*srcW)*4+2]+p[(h2+l2*srcW)*4+2]-p[(h2+l1*srcW)*4+2]-p[(h1+l2*srcW)*4+2];
				tot[3]=p[(h1+l1*srcW)*4+3]+p[(h2+l2*srcW)*4+3]-p[(h2+l1*srcW)*4+3]-p[(h1+l2*srcW)*4+3];

				dst[i]=Math.floor(Math.abs((255-jeashBG[0])-tot[0]*mul1));
				dst[i+1]=Math.floor(Math.abs((255-jeashBG[1])-tot[1]*mul1));
				dst[i+2]=Math.floor(Math.abs((255-jeashBG[2])-tot[2]*mul1));
				dst[i+3]=Math.floor(tot[3]*mul2);

				i+=4;
			}
		}
	}
	
	override public function jeashApplyFilter(surface:HTMLCanvasElement, ?refreshCache:Bool) {
		if (surface.width > 0 && surface.height > 0) {
			if (jeashKernel == null) jeashPreFilter(surface);
			var ctx: CanvasRenderingContext2D = surface.getContext('2d');

			// safety catch.
			var width = (surface.width > MAX_BLUR_WIDTH) ? MAX_BLUR_WIDTH : surface.width;
			var height = (surface.height > MAX_BLUR_HEIGHT) ? MAX_BLUR_HEIGHT : surface.height;
			var jeashImageData = ctx.getImageData (0, 0, width, height);

			jeashBoxBlur(jeashImageData.data, Math.floor(jeashImageData.width), Math.floor(jeashImageData.height), jeashKernel, Math.floor(blurX), Math.floor(blurY));

			ctx.putImageData (jeashImageData, 0, 0);
		}
	}

	public var blurX : Float;
	public var blurY : Float;
	public var quality : Int;
}
