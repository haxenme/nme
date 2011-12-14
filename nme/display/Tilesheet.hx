package nme.display;


import nme.geom.Point;
import nme.geom.Rectangle;
import nme.Loader;


class Tilesheet
{
	
	public static inline var TILE_SCALE = 0x0001;
	public static inline var TILE_ROTATION = 0x0002;
	public static inline var TILE_RGB = 0x0004;
	public static inline var TILE_ALPHA = 0x0008;
	
	/**
	 * @private
	 */
	public var nmeBitmap:BitmapData;
	
	#if (cpp || neko)
	
	/**
	 * @private
	 */
	public var nmeHandle:Dynamic;
	
	#else
	
	/**
	 * @private
	 */
	public var nmeTilePoints:Array<Point>;
	
	/**
	 * @private
	 */
	public var nmeTiles:Array<Rectangle>;
	
	#end
	
	
	public function new(inImage:BitmapData)
	{
		nmeBitmap = inImage;
		
		#if (cpp || neko)
		
		nmeHandle = nme_tilesheet_create(inImage.nmeHandle);
		
		#else
		
		nmeTilePoints = new Array<Point>();
		nmeTiles = new Array<Rectangle>();
		
		#end
	}
	
	
	public function addTileRect(inRect:Rectangle, ?inHotSpot:Point)
	{
		#if (cpp || neko)
		
		nme_tilesheet_add_rect(nmeHandle, inRect, inHotSpot);
		
		#else
		
		nmeTiles.push(inRect);
		nmeTilePoints.push(inHotSpot);
		
		#end
	}
	
	
	public function drawTiles (graphics:Graphics, inXYID:Array<Float>, inSmooth:Bool = false, inFlags:Int = 0):Void
	{
		#if (cpp || neko)
		
		graphics.drawTiles (this, inXYID, inSmooth, inFlags);
		
		#else
		
		var useScale = (inFlags & TILE_SCALE) > 0;
		var useRotation = (inFlags & TILE_ROTATION) > 0;
		var useRGB = (inFlags & TILE_RGB) > 0;
		var useAlpha = (inFlags & TILE_ALPHA) > 0;
		
		var index = 0;
		
		graphics.beginBitmapFill (nmeBitmap, null, false, inSmooth);
		
		while (index < inXYID.length)
		{
			var x = inXYID[index];
			var y = inXYID[index + 1];
			var tileID = Std.int (inXYID[index + 2]);
			index += 3;
			
			var tile = nmeTiles[tileID];
			var centerPoint = nmeTilePoints[tileID];
			
			var scale = 1.0;
			var rotation = 0.0;
			var alpha = 1.0;
			
			if (useScale)
			{
				scale = inXYID[index];
				index ++;
			}
			
			if (useRotation)
			{
				rotation = inXYID[index];
				index ++;
			}
			
			if (useRGB)
			{
				//ignore for now
				index += 3;
			}
			
			if (useAlpha)
			{
				alpha = inXYID[index];
				index++;
			}
			
			//graphics.drawTriangles(
		}
		
		#end
	}
	
	
	
	// Native Methods
	
	
	
	#if (cpp || neko)
	
	private static var nme_tilesheet_create = Loader.load("nme_tilesheet_create", 1);
	private static var nme_tilesheet_add_rect = Loader.load("nme_tilesheet_add_rect", 3);
	
	#end
	
}