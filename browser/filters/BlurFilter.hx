package browser.filters;
#if js


import browser.display.BitmapData;
import browser.geom.Point;
import browser.geom.Rectangle;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.Uint8ClampedArray;
import nme.Vector;


class BlurFilter extends BitmapFilter {
	
	
	public var blurX:Float;
	public var blurY:Float;
	public var quality:Int;
	
	private var MAX_BLUR_WIDTH:Int;
	private var MAX_BLUR_HEIGHT:Int;
	private var nmeBG:Array<Int>;
	private var nmeKernel:Vector<Int>;
	
	
	public function new(inBlurX:Float = 4, inBlurY:Float = 4, inQuality:Int = 1) {
		
		super("BlurFilter");
		
		blurX = (inBlurX==null ? 4.0 : inBlurX);
		blurY = (inBlurY==null ? 4.0 : inBlurY);
		
		MAX_BLUR_WIDTH = Lib.current.stage.stageWidth;
		MAX_BLUR_HEIGHT = Lib.current.stage.stageHeight;
		
		quality = (inQuality==null ? 1 : inQuality);
		var bgColor = Lib.current.stage.backgroundColor;
		nmeBG = [(bgColor & 0xFF0000) >>> 16,(bgColor & 0x00FF00) >>> 8,(bgColor & 0x0000FF)];
		
	}
	
	
	public function applyFilter(inBitmapData:BitmapData, inRect:Rectangle, inPoint:Point, inBitmapFilter:BitmapFilter):Void {
		
		
		
	}
	
	
	override public function clone():BitmapFilter {
		
		return new BlurFilter(blurX, blurY, quality);
		
	}
	
	
	override public function nmePreFilter(surface:CanvasElement):Void {
		
		var ctx:CanvasRenderingContext2D = surface.getContext('2d');
		nmeKernel = new Vector();
		
		if (surface.width == 0 || surface.height == 0) return;
		
		// safety catch.
		var width = (surface.width > MAX_BLUR_WIDTH) ? MAX_BLUR_WIDTH : surface.width;
		var height = (surface.height > MAX_BLUR_HEIGHT) ? MAX_BLUR_HEIGHT : surface.height;
		
		nmeBuildKernel(ctx.getImageData(0, 0, width, height).data, width, height, nmeKernel);
		
	}
	
	
	private function nmeBuildKernel(src:Uint8ClampedArray, srcW:Int, srcH:Int, dst:Vector<Int>):Void {
		
		// Implementation reference: http://www.gamasutra.com/features/20010209/Listing2.cpp
		
		var i = 0, j = 0, tot = [], maxW = srcW * 4;
		
		for (y in 0...srcH) {
			
			for (x in 0...srcW) {
				
				tot[0] = src[j];
				tot[1] = src[j + 1];
				tot[2] = src[j + 2];
				tot[3] = src[j + 3];
				
				if (x > 0) {
					
					tot[0] += dst[i - 4];
					tot[1] += dst[i - 3];
					tot[2] += dst[i - 2];
					tot[3] += dst[i - 1];
					
				}
				
				if (y > 0) {
					
					tot[0] += dst[i - maxW];
					tot[1] += dst[i + 1 - maxW];
					tot[2] += dst[i + 2 - maxW];
					tot[3] += dst[i + 3 - maxW];
					
				}
				
				if (x > 0 && y > 0) {
					
					tot[0] -= dst[i - maxW - 4];
					tot[1] -= dst[i - maxW - 3];
					tot[2] -= dst[i - maxW - 2];
					tot[3] -= dst[i - maxW - 1];
					
				}
				
				dst[i] = tot[0];
				dst[i + 1] = tot[1];
				dst[i + 2] = tot[2];
				dst[i + 3] = tot[3];
				
				i += 4;
				j += 4;
				
			}
			
		}
		
	}
	
	
	private function nmeBoxBlur(dst:Uint8ClampedArray, srcW:Int, srcH:Int, p:Vector<Int>, boxW:Int, boxH:Int):Void {
		
		var mul1 = 1.0 / ((boxW * 2 + 1) * (boxH * 2 + 1)), i = 0, tot = [], h1 = 0, l1 = 0, h2 = 0, l2 = 0;
		var mul2 = 1.7 / ((boxW * 2 + 1) * (boxH * 2 + 1));
		
		for (y in 0...srcH) {
			
			for (x in 0...srcW) {
				
				h1 = if (x + boxW >= srcW) srcW - 1; else(x + boxW);
				l1 = if (y + boxH >= srcH) srcH - 1; else(y + boxH);
				h2 = if (x - boxW < 0) 0; else(x - boxW);
				l2 = if (y - boxH < 0) 0; else(y - boxH);
				
				tot[0] = p[(h1 + l1 * srcW) * 4] + p[(h2 + l2 * srcW) * 4] - p[(h2 + l1 * srcW) * 4] - p[(h1 + l2 * srcW) * 4];
				tot[1] = p[(h1 + l1 * srcW) * 4 + 1] + p[(h2 + l2 * srcW) * 4 + 1] - p[(h2 + l1 * srcW) * 4 + 1] - p[(h1 + l2 * srcW) * 4 + 1];
				tot[2] = p[(h1 + l1 * srcW) * 4 + 2] + p[(h2 + l2 * srcW) * 4 + 2] - p[(h2 + l1 * srcW) * 4 + 2] - p[(h1 + l2 * srcW) * 4 + 2];
				tot[3] = p[(h1 + l1 * srcW) * 4 + 3] + p[(h2 + l2 * srcW) * 4 + 3] - p[(h2 + l1 * srcW) * 4 + 3] - p[(h1 + l2 * srcW) * 4 + 3];
				
				dst[i] = Math.floor(Math.abs((255 - nmeBG[0]) - tot[0] * mul1));
				dst[i + 1] = Math.floor(Math.abs((255 - nmeBG[1]) - tot[1] * mul1));
				dst[i + 2] = Math.floor(Math.abs((255 - nmeBG[2]) - tot[2] * mul1));
				dst[i + 3] = Math.floor(tot[3] * mul2);
				
				i += 4;
				
			}
			
		}
		
	}
	
	
	override public function nmeApplyFilter(surface:CanvasElement, refreshCache:Bool = false):Void {
		
		if (surface.width > 0 && surface.height > 0) {
			
			if (nmeKernel == null) nmePreFilter(surface);
			var ctx:CanvasRenderingContext2D = surface.getContext('2d');
			
			// safety catch.
			var width = (surface.width > MAX_BLUR_WIDTH) ? MAX_BLUR_WIDTH : surface.width;
			var height = (surface.height > MAX_BLUR_HEIGHT) ? MAX_BLUR_HEIGHT : surface.height;
			var nmeImageData = ctx.getImageData(0, 0, width, height);
			
			nmeBoxBlur(nmeImageData.data, Math.floor(nmeImageData.width), Math.floor(nmeImageData.height), nmeKernel, Math.floor(blurX), Math.floor(blurY));
			ctx.putImageData(nmeImageData, 0, 0);
			
		}
		
	}
	
	
}


#end