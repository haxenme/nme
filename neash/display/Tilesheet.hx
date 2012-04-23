package neash.display;


import neash.geom.Matrix;
import neash.geom.Point;
import neash.geom.Rectangle;
import neash.Loader;


class Tilesheet
{
	
	public static inline var TILE_SCALE = 0x0001;
	public static inline var TILE_ROTATION = 0x0002;
	public static inline var TILE_RGB = 0x0004;
	public static inline var TILE_ALPHA = 0x0008;
	
	public static inline var TILE_BLEND_NORMAL   = 0x00000000;
	public static inline var TILE_BLEND_ADD      = 0x00010000;
	
	/** @private */ public var nmeBitmap:BitmapData;
	/** @private */ public var nmeHandle:Dynamic;
	
	
	public function new(inImage:BitmapData)
	{
		nmeBitmap = inImage;
		nmeHandle = nme_tilesheet_create(inImage.nmeHandle);
	}
	
	
	public function addTileRect(rectangle:Rectangle, centerPoint:Point = null)
	{
		nme_tilesheet_add_rect(nmeHandle, rectangle, centerPoint);
	}
	
	
	/**
	 * Fast method to draw a batch of tiles using a Tilesheet
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
	 * @param	graphics		The nme.display.Graphics object to use for drawing
	 * @param	tileData		An array of all position, ID and optional values for use in drawing
	 * @param	smooth		(Optional) Whether drawn tiles should be smoothed (Default: false)
	 * @param	flags		(Optional) Flags to enable scale, rotation, RGB and/or alpha when drawing (Default: 0)
	 */
	public function drawTiles (graphics:Graphics, tileData:Array<Float>, smooth:Bool = false, flags:Int = 0):Void
	{
		graphics.drawTiles (this, tileData, smooth, flags);
	}
	
	
	
	// Native Methods
	
	
	
	private static var nme_tilesheet_create = Loader.load("nme_tilesheet_create", 1);
	private static var nme_tilesheet_add_rect = Loader.load("nme_tilesheet_add_rect", 3);
	
}