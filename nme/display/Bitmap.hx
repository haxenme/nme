package nme.display;
#if (cpp || neko)


import nme.display.DisplayObject;
import nme.display.PixelSnapping;


class Bitmap extends DisplayObject
{
	
	/**
	 * You can set the bitmapData property to change which image
	 * is displayed in the Bitmap. BitmapData objects can be shared
	 * between multiple Bitmap instances to improve performance
	 * and reduce memory usage.
	 */
	public var bitmapData(default, nmeSetBitmapData):BitmapData;
	
	/**
	 * Adjust the type of pixel snapping used when rendering the image
	 */
	public var pixelSnapping:PixelSnapping;
	
	/**
	 * Adjust whether the image should be rendered with smoothing
	 */
	public var smoothing(default, nmeSetSmoothing):Bool;
	
	private var mGraphics:Graphics;
	
	
	public function new(?inBitmapData:BitmapData, ?inPixelSnapping:PixelSnapping, ?inSmoothing:Bool):Void
	{
		super(DisplayObject.nme_create_display_object(), "Bitmap");
		
		pixelSnapping = inPixelSnapping;
		smoothing = inSmoothing;
		
		nmeSetBitmapData(inBitmapData);
	}
	
	
	private function nmeRebuid()
	{
		var gfx = graphics;
		gfx.clear();
		
		if (bitmapData != null)
		{
			gfx.beginBitmapFill(bitmapData,false,smoothing);
			gfx.drawRect(0,0,bitmapData.width,bitmapData.height);
			gfx.endFill();
		}
	}
	
	
	
	// Getters & Setters
	
	
	
	private function nmeSetBitmapData(inBitmapData:BitmapData):BitmapData
	{
		bitmapData = inBitmapData;
		nmeRebuid();
		
		return inBitmapData;
	}
	
	
	private function nmeSetSmoothing(inSmooth:Bool):Bool
	{
		smoothing = inSmooth;
		nmeRebuid();
		
		return inSmooth;
	}
	
}


#elseif js


import nme.display.DisplayObject;
import nme.display.BitmapData;
import nme.display.PixelSnapping;
import nme.geom.Rectangle;
import nme.geom.Matrix;
import nme.geom.Point;

import Html5Dom;

class Bitmap extends DisplayObject {
	public var bitmapData(default,jeashSetBitmapData) : BitmapData;
	public var pixelSnapping : PixelSnapping;
	public var smoothing : Bool;

	public var jeashGraphics(default,null):Graphics;
	var jeashCurrentLease:ImageDataLease;

	public function new(?inBitmapData : BitmapData, ?inPixelSnapping : PixelSnapping, ?inSmoothing : Bool) : Void {
		super();
		pixelSnapping = inPixelSnapping;
		smoothing = inSmoothing;
		name = "Bitmap " + DisplayObject.mNameID++;

		jeashGraphics = new Graphics();

		if (inBitmapData != null) {
			jeashSetBitmapData(inBitmapData);
		}

		Lib.jeashSetSurfaceId(jeashGraphics.jeashSurface, name);
	}

	public function jeashSetBitmapData(inBitmapData:BitmapData) : BitmapData {
		jeashInvalidateBounds();
		bitmapData = inBitmapData;
		return inBitmapData;
	}

	override function jeashGetGraphics() return jeashGraphics
	
	override function BuildBounds() {
		super.BuildBounds();
				
		if(bitmapData!=null)
		{
			var r:Rectangle = new Rectangle(0, 0, bitmapData.width, bitmapData.height);		
			
			if (r.width!=0 || r.height!=0)
			{
				if (mBoundsRect.width==0 && mBoundsRect.height==0)
					mBoundsRect = r.clone();
				else
					mBoundsRect.extendBounds(r);
			}
		}
	}

	function jeashApplyFilters(surface:HTMLCanvasElement) {
		if (jeashFilters != null) {
				for (filter in jeashFilters) {
					filter.jeashApplyFilter(jeashGraphics.jeashSurface);
				}
		} 
	}

	override public function jeashRender(parentMatrix:Matrix, ?inMask:HTMLCanvasElement) {
		if (bitmapData == null) return;
		if(mMtxDirty || mMtxChainDirty){
			jeashValidateMatrix();
		}

		var m = mFullMatrix.clone();
		var imageDataLease = bitmapData.jeashGetLease();
		if (imageDataLease != null && (jeashCurrentLease == null || imageDataLease.seed != jeashCurrentLease.seed || imageDataLease.time != jeashCurrentLease.time)) {
			var srcCanvas = bitmapData.handle();
			jeashGraphics.jeashSurface.width = srcCanvas.width;
			jeashGraphics.jeashSurface.height = srcCanvas.height;
			jeashGraphics.clear();
			Lib.jeashDrawToSurface(srcCanvas, jeashGraphics.jeashSurface);
			jeashCurrentLease = imageDataLease.clone();

			jeashApplyFilters(jeashGraphics.jeashSurface);
		} else if (inMask != null) {
			jeashApplyFilters(jeashGraphics.jeashSurface);
		}

		if (inMask != null) {
			Lib.jeashDrawToSurface(jeashGraphics.jeashSurface, inMask, m, (parent != null ? parent.alpha : 1) * alpha);
		} else {

			Lib.jeashSetSurfaceTransform(jeashGraphics.jeashSurface, m);
			Lib.jeashSetSurfaceOpacity(jeashGraphics.jeashSurface, (parent != null ? parent.alpha : 1) * alpha);
		}

	}

	override public function jeashGetObjectUnderPoint(point:Point):DisplayObject 
		if (!visible) return null; 
		else if (this.bitmapData != null) {
			var local = globalToLocal(point);
			if (local.x < 0 || local.y < 0 || local.x > width || local.y > height) return null; else return cast this;
		}
		else return super.jeashGetObjectUnderPoint(point)

}


#else
typedef Bitmap = flash.display.Bitmap;
#end