package nme.display;
#if !jeash


import nme.geom.ColorTransform;
import nme.geom.Matrix;
import nme.geom.Point;
import nme.geom.Rectangle;
import nme.Loader;

#if (!cpp && !neko)
class ColoredTile {
    public var tilesheet: Tilesheet;
    public var tileRect: Rectangle;
	var rect: Rectangle;
    
    public var bitmap: BitmapData;
	var color: ColorTransform;
	public var vertices: Vector<Float>;
    
    public function new(inTilesheet: Tilesheet, inTileRect: Rectangle) {
        tilesheet = inTilesheet;
        tileRect = inTileRect;
		rect = new Rectangle(0, 0, tileRect.width, tileRect.height);
		color = new ColorTransform();
		vertices = new Vector<Float>(8, true);
		bitmap = new BitmapData(Std.int(tileRect.width), Std.int(tileRect.height), true, 0);
    }
    
	public function setColor(red: Float, green: Float, blue: Float, alpha: Float) {
		bitmap.copyPixels(tilesheet.nmeBitmap, tileRect, new Point(0, 0));
		color.redMultiplier = red;
		color.greenMultiplier = green;
		color.blueMultiplier = blue;
		color.alphaMultiplier = alpha;
		bitmap.colorTransform(rect, color);
	}
	
}
#end

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
	
	static private var defaultRatio:Point = new Point(0, 0);
	private var bitmapHeight:Int;
	private var bitmapWidth:Int;
	private var tilePoints:Array<Point>;
	private var tiles:Array<Rectangle>;
	private var tileUVs:Array<Rectangle>;
	private var _ids:Vector<Int>;
	private var _vertices:Vector<Float>;
	private var _indices:Vector<Int>;
	private var _uvs:Vector<Float>;
	
	private var coloredTiles: Array<ColoredTile>;
	private var _coloredIds: Vector<Int>;
	
	private static var coloredIndices: Vector<Int>;
	private static var coloredUvs: Vector<Float>;
	
	#end
	
	
	public function new(inImage:BitmapData)
	{
		nmeBitmap = inImage;
		
		#if (cpp || neko)
		
		nmeHandle = nme_tilesheet_create(inImage.nmeHandle);
		
		#else
		
		bitmapWidth = nmeBitmap.width;
		bitmapHeight = nmeBitmap.height;
		
		tilePoints = new Array<Point>();
		tiles = new Array<Rectangle>();
		tileUVs = new Array<Rectangle>();
		_ids = new Vector<Int>();
		_vertices = new Vector<Float>();
		_indices = new Vector<Int>();
		_uvs = new Vector<Float>();
		
		coloredTiles = [];
		_coloredIds = new Vector<Int>();
		if (coloredIndices == null) {
			coloredIndices = new Vector<Int>();
			adjustIndices(coloredIndices, 6);
			coloredUvs = new Vector<Float>(8, true);
			coloredUvs[0] = coloredUvs[4] = 0;
			coloredUvs[1] = coloredUvs[3] = 0;
			coloredUvs[2] = coloredUvs[6] = 1;
			coloredUvs[5] = coloredUvs[7] = 1;
		}
		#end
	}
	
	
	public function addTileRect(rectangle:Rectangle, centerPoint:Point = null)
	{
		#if (cpp || neko)
		
		nme_tilesheet_add_rect(nmeHandle, rectangle, centerPoint);
		
		#else
		
		tiles.push(rectangle);
		if (centerPoint == null) tilePoints.push(defaultRatio);
		else tilePoints.push(new Point(centerPoint.x / rectangle.width, centerPoint.y / rectangle.height));	
		tileUVs.push(new Rectangle(rectangle.left / bitmapWidth, rectangle.top / bitmapHeight, rectangle.right / bitmapWidth, rectangle.bottom / bitmapHeight));
		
		#end
	}
	
	
	#if (!cpp && !neko)
	
	private function adjustIDs(vec:Vector<Int>, len:UInt)
	{
		if (vec.length != len)
		{
			var prevLen = vec.length;
			vec.fixed = false;
			vec.length = len;
			vec.fixed = true;
			for(i in prevLen...len)
				vec[i] = -1;
		}
		return vec;
	}
	
	
	private function adjustIndices(vec:Vector<Int>, len:UInt)
	{
		if (vec.length != len)
		{
			vec.fixed = false;
			if (vec.length > len)
			{
				vec.length = len;
				vec.fixed = true;
			}
			else 
			{
				var offset6 = vec.length;
				var offset4 = cast(4 * offset6 / 6, Int);
				vec.length = len;
				vec.fixed = true;
				while (offset6 < len)
				{
					vec[offset6] = 0 + offset4;
					vec[offset6 + 1] = vec[offset6 + 3] = 1 + offset4;
					vec[offset6 + 2] = vec[offset6 + 5] = 2 + offset4;
					vec[offset6 + 4] = 3 + offset4;
					offset4 += 4;
					offset6 += 6;
				}
			}
		}
		return vec;
	}
	
	
	private function adjustLen(vec:Vector<Float>, len:UInt)
	{
		if (vec.length != len)
		{
			vec.fixed = false;
			vec.length = len;
			vec.fixed = true;
		}
		return vec;
	}
	
	#end
	
	
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
		#if (cpp || neko)
		
		graphics.drawTiles (this, tileData, smooth, flags);
		
		#else
		
		var useScale = (flags & TILE_SCALE) > 0;
		var useRotation = (flags & TILE_ROTATION) > 0;
		var useRGB = (flags & TILE_RGB) > 0;
		var useAlpha = (flags & TILE_ALPHA) > 0;
		
		if (useScale || useRotation || useRGB || useAlpha)
		{
			var scaleIndex = 0;
			var rotationIndex = 0;
			var rgbIndex = 0;
			var alphaIndex = 0;
			var numValues = 3;
			var transColor = false;
			
			if (useScale)
			{
				scaleIndex = numValues;
				numValues ++;
			}
			
			if (useRotation)
			{
				rotationIndex = numValues;
				numValues ++;
			}
			
			if (useRGB)
			{
				transColor = true;
				rgbIndex = numValues;
				numValues += 3;
			}
			
			if (useAlpha)
			{
				transColor = true;
				alphaIndex = numValues;
				numValues ++;
			}
			
			var totalCount = tileData.length;
			var itemCount = Std.int (totalCount / numValues);
			
			var ids: Vector<Int> = null, vertices: Vector<Float> = null, uvtData: Vector<Float> = null, indices: Vector<Int> = null;
			var coloredIds: Vector<Int> = null;
			if (!transColor) {
				ids = adjustIDs(_ids, itemCount);
				vertices = adjustLen(_vertices, itemCount * 8); 
				indices = adjustIndices(_indices, itemCount * 6); 
				uvtData = adjustLen(_uvs, itemCount * 8); 
			} else {
				coloredIds = adjustIDs(_coloredIds, itemCount);
			}
			var index = 0;
			var offset8 = 0;
			var tileIndex:Int = 0;
			var tileID:Int = 0;
			var cacheID:Int = -1;
			
			var tile:Rectangle = null;
			var tileUV:Rectangle = null;
			var tilePoint:Point = null;
			var tileHalfHeight:Float = 0;
			var tileHalfWidth:Float = 0;
			var tileHeight:Float = 0;
			var tileWidth:Float = 0;

			while (index < totalCount)
			{
				var x = tileData[index];
				var y = tileData[index + 1];
				var tileID = Std.int(tileData[index + 2]);
				var scale = 1.0;
				var rotation = 0.0;
				
				if (useScale)
				{
					scale = tileData[index + scaleIndex];
				}
				
				if (useRotation)
				{
					rotation = tileData[index + rotationIndex];
				}
				
				if (cacheID != tileID)
				{
					cacheID = tileID;
					tile = tiles[tileID];
					tileUV = tileUVs[tileID];
					tilePoint = tilePoints[tileID];
				}
				
				if (transColor) {
					var red = 1.0, green = 1.0, blue = 1.0, alpha = 1.0;
				    if (useRGB) {
                        red = tileData[index + rgbIndex];
                        green = tileData[index + rgbIndex + 1];
                        blue = tileData[index + rgbIndex + 2];
                    }
					if (useAlpha) alpha = tileData[index + alphaIndex];
					var coloredtile: ColoredTile = null;
					if ((coloredtile = coloredTiles[tileID]) == null) {
						coloredtile = coloredTiles[tileID] = new ColoredTile(this, tile);
					}
					coloredIds[tileIndex] = tileID;
					coloredtile.setColor(red, green, blue, alpha);
					vertices = coloredtile.vertices;
					offset8 = 0;
                }
				
				var tileWidth = tile.width * scale;
				var tileHeight = tile.height * scale;
				
				if (rotation != 0)
				{
					var kx = tilePoint.x * tileWidth;
					var ky = tilePoint.y * tileHeight;
					var akx = (1 - tilePoint.x) * tileWidth;
					var aky = (1 - tilePoint.y) * tileHeight;
					var ca = Math.cos(rotation);
					var sa = Math.sin(rotation);
					var xc = kx * ca, xs = kx * sa, yc = ky * ca, ys = ky * sa;
					var axc = akx * ca, axs = akx * sa, ayc = aky * ca, ays = aky * sa;
					vertices[offset8] = x - (xc + ys);
					vertices[offset8 + 1] = y - (-xs + yc);
					vertices[offset8 + 2] = x + axc - ys;
					vertices[offset8 + 3] = y - (axs + yc);
					vertices[offset8 + 4] = x - (xc - ays);
					vertices[offset8 + 5] = y + xs + ayc;
					vertices[offset8 + 6] = x + axc + ays;
					vertices[offset8 + 7] = y + (-axs + ayc);
				}
				else 
				{
					x -= tilePoint.x * tileWidth;
					y -= tilePoint.y * tileHeight;
					vertices[offset8] = vertices[offset8 + 4] = x;
					vertices[offset8 + 1] = vertices[offset8 + 3] = y;
					vertices[offset8 + 2] = vertices[offset8 + 6] = x + tileWidth;
					vertices[offset8 + 5] = vertices[offset8 + 7] = y + tileHeight;
				}
				
				if (!transColor && ids[tileIndex] != tileID)
				{
					ids[tileIndex] = tileID;
					uvtData[offset8] = uvtData[offset8 + 4] = tileUV.left;
					uvtData[offset8 + 1] = uvtData[offset8 + 3] = tileUV.top;
					uvtData[offset8 + 2] = uvtData[offset8 + 6] = tileUV.width;
					uvtData[offset8 + 5] = uvtData[offset8 + 7] = tileUV.height;
				}
				
				offset8 += 8;
				index += numValues;
				tileIndex++;
			}
			if (transColor) {
				for (tid in coloredIds) {
					var ct = coloredTiles[tid];
					graphics.beginBitmapFill(ct.bitmap, null, false, smooth);
					graphics.drawTriangles(ct.vertices, coloredIndices, coloredUvs);
					graphics.endFill();
				}
			} else {
				graphics.beginBitmapFill (nmeBitmap, null, false, smooth);
				graphics.drawTriangles (vertices, indices, uvtData);
			}
			
		}
		else
		{
			
			var index = 0;
			var matrix = new Matrix ();
			
			while (index < tileData.length)
			{
				var x = tileData[index];
				var y = tileData[index + 1];
				var tileID = Std.int (tileData[index + 2]);
				index += 3;
				
				var tile = tiles[tileID];
				var centerPoint = tilePoints[tileID];
				var ox = centerPoint.x * tile.width, oy = centerPoint.y * tile.height;
				
				var scale = 1.0;
				var rotation = 0.0;
				var alpha = 1.0;
				
				matrix.tx = x - tile.x - ox;
				matrix.ty = y - tile.y - oy;
				
				// need to add support for rotation, alpha, scale and RGB
				
				graphics.beginBitmapFill (nmeBitmap, matrix, false, smooth);
				graphics.drawRect (x - ox, y - oy, tile.width, tile.height);
			}
			
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


#else
typedef Tilesheet = jeash.display.Tilesheet;
#end