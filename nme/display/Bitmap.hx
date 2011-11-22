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


#else
typedef Bitmap = flash.display.Bitmap;
#end