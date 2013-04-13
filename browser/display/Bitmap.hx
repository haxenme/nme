package browser.display;
#if js


import browser.display.DisplayObject;
import browser.display.BitmapData;
import browser.display.PixelSnapping;
import browser.geom.Matrix;
import browser.geom.Point;
import browser.geom.Rectangle;
import js.html.CanvasElement;


class Bitmap extends DisplayObject {
	
	
	public var bitmapData(default, set_bitmapData):BitmapData;
	public var pixelSnapping:PixelSnapping;
	public var smoothing:Bool;

	public var nmeGraphics(default, null):Graphics;
	private var nmeCurrentLease:ImageDataLease;
	private var nmeInit:Bool;
	
	
	public function new(inBitmapData:BitmapData = null, inPixelSnapping:PixelSnapping = null, inSmoothing:Bool = false):Void {
		
		super();
		
		pixelSnapping = inPixelSnapping;
		smoothing = inSmoothing;
		
		if (inBitmapData != null) {
			
			this.bitmapData = inBitmapData;
			bitmapData.nmeReferenceCount++;
			
			if (bitmapData.nmeReferenceCount == 1) {
				
				nmeGraphics = new Graphics(bitmapData.handle());
				
			}
			
		}
		
		if (nmeGraphics == null) {
			
			nmeGraphics = new Graphics();
			
		}
		
		if (bitmapData != null) {
			
			nmeRender();
			
		}
		
	}
	
	
	private inline function getBitmapSurfaceTransform(gfx:Graphics):Matrix {
		
		var extent = gfx.nmeExtentWithFilters;
		var fm = nmeGetFullMatrix();
		fm.nmeTranslateTransformed(extent.topLeft);
		return fm;
		
	}
	
	
	override private function nmeGetGraphics():Graphics {
		
		return nmeGraphics;
		
	}
	
	
	override public function nmeGetObjectUnderPoint(point:Point):DisplayObject {
		
		if (!visible) {
			
			return null;
			
		} else if (this.bitmapData != null) {
			
			var local = globalToLocal(point);
			
			if (local.x < 0 || local.y < 0 || local.x > width || local.y > height) {
				
				return null;
				
			} else {
				
				return cast this;
				
			}
			
		} else {
			
			return super.nmeGetObjectUnderPoint(point);
			
		}
		
	}
	
	
	override public function nmeRender(inMask:CanvasElement = null, clipRect:Rectangle = null):Void {
		
		if (!nmeCombinedVisible) return;
		if (bitmapData == null) return;
		
		if (_matrixInvalid || _matrixChainInvalid) {
			
			nmeValidateMatrix();
			
		}
		
		if (bitmapData.handle() != nmeGraphics.nmeSurface) {
			
			var imageDataLease = bitmapData.nmeGetLease();
			
			if (imageDataLease != null && (nmeCurrentLease == null || imageDataLease.seed != nmeCurrentLease.seed || imageDataLease.time != nmeCurrentLease.time)) {
				
				var srcCanvas = bitmapData.handle();
				
				nmeGraphics.nmeSurface.width = srcCanvas.width;
				nmeGraphics.nmeSurface.height = srcCanvas.height;
				nmeGraphics.clear();
				
				Lib.nmeDrawToSurface(srcCanvas, nmeGraphics.nmeSurface);
				nmeCurrentLease = imageDataLease.clone();
				
				handleGraphicsUpdated(nmeGraphics);
				
			}
			
		}
		
		if (inMask != null) {
			
			nmeApplyFilters(nmeGraphics.nmeSurface);
			var m = getBitmapSurfaceTransform(nmeGraphics);
			Lib.nmeDrawToSurface(nmeGraphics.nmeSurface, inMask, m,(parent != null ? parent.nmeCombinedAlpha : 1) * alpha, clipRect);
			
		} else {
			
			if (nmeTestFlag(DisplayObject.TRANSFORM_INVALID)) {
				
				var m = getBitmapSurfaceTransform(nmeGraphics);
				Lib.nmeSetSurfaceTransform(nmeGraphics.nmeSurface, m);
				nmeClearFlag(DisplayObject.TRANSFORM_INVALID);
				
			}
			
			if (!nmeInit) {
				
				Lib.nmeSetSurfaceOpacity(nmeGraphics.nmeSurface, 0);
				nmeInit = true;
				
			} else {
				
				Lib.nmeSetSurfaceOpacity(nmeGraphics.nmeSurface, (parent != null ? parent.nmeCombinedAlpha : 1) * alpha);
				
			}
			
		}
		
	}
	
	
	override public function toString():String {
		
		return "[Bitmap name=" + this.name + " id=" + _nmeId + "]";
		
	}
	
	
	override function validateBounds():Void {
		
		if (_boundsInvalid) {
			
			super.validateBounds();
			
			if (bitmapData != null) {
				
				var r = new Rectangle(0, 0, bitmapData.width, bitmapData.height);		
				
				if (r.width != 0 || r.height != 0) {
					
					if (nmeBoundsRect.width == 0 && nmeBoundsRect.height == 0) {
						
						nmeBoundsRect = r.clone();
						
					} else {
						
						nmeBoundsRect.extendBounds(r);
						
					}
					
				}
				
			}
			
			nmeSetDimensions();
			
		}
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function set_bitmapData(inBitmapData:BitmapData):BitmapData {
		
		if (inBitmapData != bitmapData) {
			
			if (bitmapData != null) {
				
				bitmapData.nmeReferenceCount--;
				
				if (nmeGraphics.nmeSurface == bitmapData.handle()) {
					
					Lib.nmeSetSurfaceOpacity(bitmapData.handle(), 0);
					
				}
				
			}
			
			if (inBitmapData != null) {
				
				inBitmapData.nmeReferenceCount++;
				
			}
			
		}
		
		nmeInvalidateBounds();
		bitmapData = inBitmapData;
		return inBitmapData;
		
	}
	
	
}


#end