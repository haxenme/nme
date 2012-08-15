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

package jeash.display;

import jeash.display.DisplayObject;
import jeash.display.BitmapData;
import jeash.display.PixelSnapping;
import jeash.geom.Rectangle;
import jeash.geom.Matrix;
import jeash.geom.Point;

import jeash.Html5Dom;

class Bitmap extends jeash.display.DisplayObject
{
	public var bitmapData(default, jeashSetBitmapData):BitmapData;
	public var pixelSnapping:PixelSnapping;
	public var smoothing:Bool;

	public var jeashGraphics(default,null):Graphics;
	var jeashCurrentLease:ImageDataLease;

	public function new(?inBitmapData : BitmapData, ?inPixelSnapping : PixelSnapping, ?inSmoothing : Bool) : Void {
		super();
		pixelSnapping = inPixelSnapping;
		smoothing = inSmoothing;

		jeashGraphics = new Graphics();

		if (inBitmapData != null) {
			jeashSetBitmapData(inBitmapData);
			jeashRender();
		}
	}

	override public function toString() { return "[Bitmap name=" + this.name + " id=" + _jeashId + "]"; }

	public function jeashSetBitmapData(inBitmapData:BitmapData):BitmapData {
		jeashInvalidateBounds();
		bitmapData = inBitmapData;
		return inBitmapData;
	}

	override private function jeashGetGraphics() return jeashGraphics
	
	override function validateBounds() {
		if (_boundsInvalid) {
			super.validateBounds();
			if (bitmapData != null) {
				var r:Rectangle = new Rectangle(0, 0, bitmapData.width, bitmapData.height);		
				
				if (r.width != 0 || r.height != 0) {
					if (jeashBoundsRect.width == 0 && jeashBoundsRect.height == 0)
						jeashBoundsRect = r.clone();
					else
						jeashBoundsRect.extendBounds(r);
				}
			}			
			jeashSetDimensions();
		}
	}

	override public function jeashRender(?inMask:HTMLCanvasElement, ?clipRect:Rectangle) {
		if (!jeashVisible) return;
		if (bitmapData == null) return;

		if (_matrixInvalid || _matrixChainInvalid)
			jeashValidateMatrix();

		var imageDataLease = bitmapData.jeashGetLease();
		if (imageDataLease != null && (jeashCurrentLease == null || imageDataLease.seed != jeashCurrentLease.seed || imageDataLease.time != jeashCurrentLease.time)) {
			var srcCanvas = bitmapData.handle();
			jeashGraphics.jeashSurface.width = srcCanvas.width;
			jeashGraphics.jeashSurface.height = srcCanvas.height;
			jeashGraphics.clear();
			Lib.jeashDrawToSurface(srcCanvas, jeashGraphics.jeashSurface);
			jeashCurrentLease = imageDataLease.clone();

			handleGraphicsUpdated(jeashGraphics);
		}

		var fullAlpha = (parent != null ? parent.alpha : 1) * alpha;
		if (inMask != null) {
			jeashApplyFilters(jeashGraphics.jeashSurface);
			var m = getBitmapSurfaceTransform(jeashGraphics);
			Lib.jeashDrawToSurface(jeashGraphics.jeashSurface, inMask, m, fullAlpha, clipRect);
		} else {
			if (jeashTestFlag(DisplayObject.TRANSFORM_INVALID)) {
				var m = getBitmapSurfaceTransform(jeashGraphics);
				Lib.jeashSetSurfaceTransform(jeashGraphics.jeashSurface, m);
				jeashClearFlag(DisplayObject.TRANSFORM_INVALID);
			}
			if (fullAlpha != _lastFullAlpha) {
				Lib.jeashSetSurfaceOpacity(jeashGraphics.jeashSurface, fullAlpha);
				_lastFullAlpha = fullAlpha;
			}
		}		
	}

	private inline function getBitmapSurfaceTransform(gfx:Graphics):Matrix {
		var extent = gfx.jeashExtentWithFilters;
		var fm = jeashGetFullMatrix();
		fm.jeashTranslateTransformed(extent.topLeft);
		return fm;
	}

	override public function jeashGetObjectUnderPoint(point:Point):DisplayObject {
		if (!visible) return null; 
		else if (this.bitmapData != null) {
			var local = globalToLocal(point);
			if (local.x < 0 || local.y < 0 || local.x > width || local.y > height) return null; else return cast this;
		}
		else return super.jeashGetObjectUnderPoint(point);
	}
}
