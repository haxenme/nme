package nme.display;
#if (cpp || neko)


import nme.geom.Point;
import nme.geom.Rectangle;
import nme.Loader;


class Tilesheet
{
	
	public var nmeBitmap:BitmapData;
	public var nmeHandle:Dynamic;
	
	
	public function new(inImage:BitmapData)
	{
		nmeBitmap = inImage;
		nmeHandle = nme_tilesheet_create(inImage.nmeHandle);
	}
	
	
	public function addTileRect(inRect:Rectangle, ?inHotSpot:Point)
	{
		nme_tilesheet_add_rect(nmeHandle, inRect, inHotSpot);
	}
	
	
	
	// Native Methods
	
	
	
	private static var nme_tilesheet_create = Loader.load("nme_tilesheet_create", 1);
	private static var nme_tilesheet_add_rect = Loader.load("nme_tilesheet_add_rect", 3);
	
}


#else
#error "Tilesheets are only for cpp or neko targets."
#end