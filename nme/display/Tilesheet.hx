package nme.display;


import nme.geom.Point;
import nme.geom.Rectangle;
import nme.Loader;


class Tilesheet
{
	
	/**
	 * @private
	 */
	public var nmeBitmap:BitmapData;
	
	/**
	 * @private
	 */
	public var nmeHandle:Dynamic;
	
	
	public function new(inImage:BitmapData)
	{
		nmeBitmap = inImage;
		#if (cpp || neko)
		nmeHandle = nme_tilesheet_create(inImage.nmeHandle);
		#end
	}
	
	
	public function addTileRect(inRect:Rectangle, ?inHotSpot:Point)
	{
		#if (cpp || neko)
		nme_tilesheet_add_rect(nmeHandle, inRect, inHotSpot);
		#end
	}
	
	
	
	// Native Methods
	
	
	
	#if (cpp || neko)
	private static var nme_tilesheet_create = Loader.load("nme_tilesheet_create", 1);
	private static var nme_tilesheet_add_rect = Loader.load("nme_tilesheet_add_rect", 3);
	#end
	
}