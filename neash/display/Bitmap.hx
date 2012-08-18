package neash.display;


import neash.display.DisplayObject;
import neash.display.PixelSnapping;


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
	 * Adjust whether the image should be rendered with smoothing
	 */
	public var smoothing(default, nmeSetSmoothing):Bool;
	
	/** @private */ private var mGraphics:Graphics;
	
	
	public function new(bitmapData:BitmapData = null, pixelSnapping:PixelSnapping = null, smoothing:Bool = false):Void
	{
		super(DisplayObject.nme_create_display_object(), "Bitmap");
		
		this.pixelSnapping = pixelSnapping == null ? PixelSnapping.AUTO : pixelSnapping;
		this.smoothing = smoothing;
		
		if (bitmapData != null)
		{	
			nmeSetBitmapData (bitmapData);	
		}
		else if (this.bitmapData != null)
		{
			nmeRebuild ();	
		}
	}
	
	
	/** @private */ private function nmeRebuild()
	{
		if (nmeHandle != null && bitmapData != null)
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
	}
	
	
	
	// Getters & Setters
	
	
	
	/** @private */ private function nmeSetBitmapData(inBitmapData:BitmapData):BitmapData
	{
		bitmapData = inBitmapData;
		nmeRebuild();
		
		return inBitmapData;
	}
	
	
	/** @private */ private function nmeSetSmoothing(inSmooth:Bool):Bool
	{
		smoothing = inSmooth;
		nmeRebuild();
		
		return inSmooth;
	}
	
}
