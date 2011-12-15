package nme.display;


import flash.geom.Matrix;
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
	
	
	/**
	 * Fast method to draw a batch of tiles using a Tilesheet (C++ only)
	 * 
	 * The input array accepts the x, y and tile ID for each tile you wish to draw.
	 * For example, an array of [ 0, 0, 0, 10, 10, 1 ] would draw tile 0 to (0, 0) and
	 * tile 1 to (10, 10)
	 * 
	 * You can also set flags for TILE_SCALE, TILE_ROTATION, TILE_RGB and
	 * TILE_ALPHA.
	 * 
	 * Depending on which flags are active, this is the full order of the array:
	 * 
	 * [ x, y, tile ID, scale, rotation, red, green, blue, alpha, x, y ... ]
	 * 
	 * @param	sheet		The Tilesheet to use when drawing
	 * @param	inXYID		An array of all position, ID and optional values for use in drawing
	 * @param	inSmooth		(Optional) Whether drawn tiles should be smoothed (Default: false)
	 * @param	inFlags		(Optional) Flags to enable scale, rotation, RGB and/or alpha when drawing (Default: 0)
	 */
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
		var matrix = new Matrix ();
		
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
			
			matrix.tx = x - tile.x;
			matrix.ty = x - tile.y;
			
			// need to add support for rotation, alpha, scale and RGB
			
			//bitmapData.copyPixels (nmeBitmap, tile, new Point (x, y));
			graphics.beginBitmapFill (nmeBitmap, matrix, false, inSmooth);
			graphics.drawRect (x, y, tile.width, tile.height);
		}
		
		graphics.endFill ();
		
		#end
	}
	
	
	
	// Native Methods
	
	
	
	#if (cpp || neko)
	
	private static var nme_tilesheet_create = Loader.load("nme_tilesheet_create", 1);
	private static var nme_tilesheet_add_rect = Loader.load("nme_tilesheet_add_rect", 3);
	
	#end
	
}