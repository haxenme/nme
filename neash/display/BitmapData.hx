package neash.display;


import haxe.io.Bytes;
import neash.geom.Rectangle;
import neash.geom.Point;
import neash.geom.Matrix;
import neash.geom.ColorTransform;
import neash.filters.BitmapFilter;
import neash.utils.ByteArray;
import neash.Loader;


/**
* @author   Hugh Sanderson
* @author   Russell Weir
* @todo getPixel, getPixel32 should be optimized to use library methods
*/
class BitmapData implements IBitmapDrawable
{
	
	public static var CLEAR = createColor(0, 0);
	public static var BLACK = createColor(0x000000);
	public static var WHITE = createColor(0x000000);
	public static var RED = createColor(0xff0000);
	public static var GREEN = createColor(0x00ff00);
	public static var BLUE = createColor(0x0000ff);
	public inline static var PNG = "png";
	public inline static var JPG = "jpg";
	
	public static var TRANSPARENT = 0x0001;
	public static var HARDWARE = 0x0002;
	public static var FORMAT_8888:Int = 0;
	public static var FORMAT_4444:Int = 1; //16 bit with alpha channel
	public static var FORMAT_565:Int = 2;  //16 bit 565 without alpha
	
	/**
	 * Returns the height in pixels of the bitmap data
	 */
	public var height(nmeGetHeight, null):Int;
	
	/**
	 * Returns a rectangle with the dimensions of the bitmap data
	 */
	public var rect(nmeGetRect, null):Rectangle;
	
	/**
	 * Returns whether the bitmap data includes transparency
	 */
	public var transparent(nmeGetTransparent, null):Bool;
	
	/**
	 * Returns the width in pixels of the bitmap data
	 */
	public var width(nmeGetWidth, null):Int;
	
	/**
	 * @private
	 */
	public var nmeHandle:Dynamic; // Public, but only use if you know what you are doing
	

	public function new(inWidth:Int, inHeight:Int, inTransparent:Bool = true, ?inFillRGBA:BitmapInt32)
	{
		var fill_col:Int;
		var fill_alpha:Int;
		
		if (inFillRGBA == null)
		{
			fill_col = 0xffffff;
			fill_alpha = 0xff;
		}
		else
		{
			fill_col = extractColor(inFillRGBA);
			fill_alpha = extractAlpha(inFillRGBA);
		}
		
		if (inWidth < 1 || inHeight < 1)
		{
			nmeHandle = null;
		}
		else
		{
			var flags = HARDWARE;
			
			if (inTransparent)
				flags |= TRANSPARENT;
			
			nmeHandle = nme_bitmap_data_create(inWidth, inHeight, flags, fill_col, fill_alpha);
		}
		
	}
	
	
	/**
	 * Draws the result of a bitmap data object, plus a bitmap filter, to this bitmap data
	 * @param	sourceBitmapData		The source bitmap data object
	 * @param	sourceRect		A rectangle which defines the area to use from the source bitmap data object
	 * @param	destPoint		The location to place the result in this bitmap data object
	 * @param	filter		The bitmap filter to use
	 */
	public function applyFilter(sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point, filter:BitmapFilter):Void
	{
		nme_bitmap_data_apply_filter(nmeHandle, sourceBitmapData.nmeHandle, sourceRect, destPoint, filter);
	}
	
	
	/**
	 * Fills this bitmap data object using a solid color
	 * @param	color		The color to fill
	 */
	public function clear(color:Int):Void
	{
		nme_bitmap_data_clear(nmeHandle, color);
	}
	
	
	/**
	 * Duplicates the current instance as a new bitmap data object
	 * @return		A new duplicate bitmap data object
	 */
	public function clone():BitmapData
	{
		var bm = new BitmapData(0, 0);
		bm.nmeHandle = nme_bitmap_data_clone(nmeHandle);
		return bm;
	}
	
	
	/**
	 * Applies a color transform to a portion of this bitmap data object
	 * @param	rect		A rectangular area to transform
	 * @param	colorTransform		The color transform to use
	 */
	public function colorTransform(rect:Rectangle, colorTransform:ColorTransform):Void
	{
		nme_bitmap_data_color_transform(nmeHandle, rect, colorTransform);
	}
	
	
	/**
	 * Copies a channel (red, green, blue or alpha) into another channel or object
	 * @param	sourceBitmapData		The source bitmap data object
	 * @param	sourceRect		The source rectangle to pull from
	 * @param	destPoint		The destination point on this bitmap data object
	 * @param	inSourceChannel		The source channel to copy
	 * @param	inDestChannel		The destination channel to paste into
	 */
	public function copyChannel(sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point, inSourceChannel:Int, inDestChannel:Int):Void
	{
		nme_bitmap_data_copy_channel(sourceBitmapData.nmeHandle, sourceRect, nmeHandle, destPoint, inSourceChannel, inDestChannel);
	}
	
	
	/**
	 * Copies pixels from a bitmap data object into this instance
	 * @param	sourceBitmapData		The source bitmap data object
	 * @param	sourceRect		The source rectangle to pull from
	 * @param	destPoint		The destination point on this bitmap data object
	 * @param	alphaBitmapData		(Optional) A source bitmap data object to use for alpha information
	 * @param	alphaPoint		(Optional) A source point to use when copying from the alpha bitmap data object
	 * @param	mergeAlpha		(Optional) Whether copied pixels should have their alpha merged with pixels at the destination
	 */
	public function copyPixels(sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point, ?alphaBitmapData:BitmapData, ?alphaPoint:Point, mergeAlpha:Bool = false):Void
	{
		nme_bitmap_data_copy(sourceBitmapData.nmeHandle, sourceRect, nmeHandle, destPoint, mergeAlpha);
	}
	
	
	public static inline function createColor(inRGB:Int, inAlpha:Int = 0xFF):BitmapInt32
	{
		#if neko
		return { rgb: inRGB, a: inAlpha };
		#else
		return inRGB | (inAlpha << 24);
		#end
	}
	
	
	#if cpp
	public function createHardwareSurface()
	{
		nme_bitmap_data_create_hardware_surface(nmeHandle);
	}
	
	
	public function destroyHardwareSurface()
	{
		nme_bitmap_data_destroy_hardware_surface(nmeHandle);
	}
	#end
	
	
	public function dispose()
	{
		nmeHandle = null;
	}
	
	
	public function draw(source:IBitmapDrawable, matrix:Matrix = null, colorTransform:ColorTransform = null, blendMode:String = null, clipRect:Rectangle = null, smoothing:Bool = false):Void
	{
		source.nmeDrawToSurface(nmeHandle, matrix, colorTransform, blendMode, clipRect, smoothing);
	}
	
	
	public function dumpBits():Void
	{
		nme_bitmap_data_dump_bits(nmeHandle);
	}
	
	
	public function encode(inFormat:String, inQuality:Float = 0.9):ByteArray
	{
		return nme_bitmap_data_encode(nmeHandle, inFormat, inQuality);
	}
	
	
	public static inline function extractAlpha(v:BitmapInt32):Int
	{
		#if neko
		return v.a;
		#else
		return v >>> 24;
		#end
	}
	
	
	public static inline function extractColor(v:BitmapInt32):Int
	{
		#if neko
		return v.rgb;
		#else
		return v & 0xFFFFFF;
		#end
	}
	
	
	public function fillRect(rect:Rectangle, inColour:BitmapInt32):Void
	{
		var a = extractAlpha(inColour);
		var c = extractColor(inColour);
		nme_bitmap_data_fill(nmeHandle, rect, c, a);
	}
	
	
	public function fillRectEx(rect:Rectangle, inColour:Int, inAlpha:Int = 255):Void
	{
		nme_bitmap_data_fill(nmeHandle, rect, inColour, inAlpha);
	}
	
	
	public function generateFilterRect(sourceRect:Rectangle, filter:BitmapFilter):Rectangle
	{
		var result = new Rectangle();
		nme_bitmap_data_generate_filter_rect(sourceRect, filter, result);
		return result;
	}
	
	
	public function getColorBoundsRect(mask:BitmapInt32, color:BitmapInt32, findColor:Bool = true):Rectangle
	{
		var result = new Rectangle();
		nme_bitmap_data_get_color_bounds_rect(nmeHandle, mask, color, findColor, result);
		return result;
	}
	
	
	public function getPixel(x:Int, y:Int):Int
	{
		return nme_bitmap_data_get_pixel(nmeHandle, x, y);
	}
	
	
	public function getPixel32(x:Int, y:Int):BitmapInt32
	{
		#if neko
		return nme_bitmap_data_get_pixel_rgba(nmeHandle, x, y);
		#else
		return nme_bitmap_data_get_pixel32(nmeHandle, x, y);
		#end
	}
	
	
	public function getPixels(rect:Rectangle):ByteArray
	{
		var result:ByteArray = nme_bitmap_data_get_pixels(nmeHandle, rect);
		
		if (result != null)
			result.position = result.length;
		
		return result;
	}
	
	
	public function getVector(rect:Rectangle):Array<Int>
	{
		var pixels = Std.int(rect.width * rect.height);
		
		if (pixels < 1)
			return [];
		
		var result = new Array<Int>();
		result[pixels - 1] = 0;
		
		#if cpp
		nme_bitmap_data_get_array(nmeHandle, rect, result);
		#else
		var bytes:ByteArray = nme_bitmap_data_get_pixels(nmeHandle, rect);
		bytes.position = 0;
		for (i in 0...pixels)
			result[i] = bytes.readInt();
		#end
		
		return result;
	}
	
	
	/**
	* Load from a file path
	*
	* @param inFilename Full or relative path to image file
	* @return New BitmapData instance representing file
	**/
	static public function load(inFilename:String, format:Int = 0):BitmapData
	{
		var result = new BitmapData(0, 0);
		result.nmeHandle = nme_bitmap_data_load(inFilename, format);
		return result;
	}
	
	
	/**
	* Create BitmapData from a compressed image stream.
	* PNG & JPG supported on all platforms.
	*
	* @param inBytes - A buffer of compressed image data
	* @param inAlpha - optional alpha values to go with image RGB values - there should
	*                   be width*height values.
	**/
	static public function loadFromBytes(inBytes:ByteArray, ?inRawAlpha:ByteArray):BitmapData
	{
		var result = new BitmapData(0, 0);
		result.nmeHandle = nme_bitmap_data_from_bytes(inBytes, inRawAlpha);
		return result;
	}
	
	
	/**
	* Create BitmapData from a compressed image stream.
	* PNG & JPG supported on all platforms.
	*
	* @param inBytes - A buffer of compressed image data
	* @param inAlpha - optional alpha values to go with image RGB values - there should
	*                   be width*height values.
	**/
	static public function loadFromHaxeBytes(inBytes:Bytes, ?inRawAlpha:Bytes)
	{
		return loadFromBytes(ByteArray.fromBytes(inBytes), inRawAlpha == null ? null : ByteArray.fromBytes(inRawAlpha));
	}
	
	
	public function lock()
	{
		// Handled internally...
	}
	
	
	/** @private */ public function nmeDrawToSurface(inSurface:Dynamic, matrix:Matrix, colorTransform:ColorTransform, blendMode:String, clipRect:Rectangle, smoothing:Bool):Void
	{
		// IBitmapDrawable interface...
		nme_render_surface_to_surface(inSurface, nmeHandle, matrix, colorTransform, blendMode, clipRect, smoothing);
	}
	
	
	public function perlinNoise(baseX:Float, baseY:Float, numOctaves:Int, randomSeed:Int, stitch:Bool, fractalNoise:Bool, channelOptions:Int = 7, grayScale:Bool = false, ?offsets:Array<Point>):Void
	{
		var perlin = new OptimizedPerlin (randomSeed, numOctaves);
		perlin.fill (this, baseX, baseY, 0);
	}
	
	
	public function scroll(inDX:Int, inDY:Int)
	{
		nme_bitmap_data_scroll(nmeHandle, inDX, inDY);
	}
	
	
	public function setFlags(inFlags:Int):Void
	{
		// Used for optimization
		nme_bitmap_data_set_flags(nmeHandle, inFlags);
	}
	
	
	public function setPixel(inX:Int, inY:Int, inColour:Int):Void
	{
		nme_bitmap_data_set_pixel(nmeHandle, inX, inY, inColour);
	}
	
	
	public function setPixel32(inX:Int, inY:Int, inColour:BitmapInt32):Void
	{
		#if neko
		nme_bitmap_data_set_pixel_rgba(nmeHandle, inX, inY, inColour);
		#else
		nme_bitmap_data_set_pixel32(nmeHandle, inX, inY, inColour);
		#end
	}
	
	
	public function setPixels(rect:Rectangle, pixels:ByteArray):Void
	{
		var size = Std.int(rect.width * rect.height * 4);
		pixels.checkData(Std.int(size));
		nme_bitmap_data_set_bytes(nmeHandle, rect, pixels, pixels.position);
		pixels.position += size;
	}
	
	
	public function setVector(rect:Rectangle, inPixels:Array<Int>):Void
	{
		var count = Std.int(rect.width * rect.height);
		if (inPixels.length < count)
			return;
		
		#if cpp
		nme_bitmap_data_set_array(nmeHandle, rect, inPixels);
		#else
		var bytes:ByteArray = new ByteArray();
		for (i in 0...count)
			bytes.writeInt(inPixels[i]);
		nme_bitmap_data_set_bytes(nmeHandle, rect, bytes, 0);
		#end
	}
	
	
	public function unlock(?changeRect:Rectangle)
	{
		// Handled internally...
	}
	
	public function setFormat(format:Int)
	{
		nme_bitmap_data_set_format(nmeHandle, format);
	}

	public function noise(randomSeed:Int, low:Int = 0, high:Int = 255, channelOptions:Int = 7, grayScale:Bool = false) {
		nme_bitmap_data_noise(nmeHandle, randomSeed, low, high, channelOptions, grayScale);
	}
	
	
	// Getters & Setters
	
	
	/** @private */ private function nmeGetRect():Rectangle { return new Rectangle (0, 0, width, height); }
	/** @private */ private function nmeGetWidth():Int { return nme_bitmap_data_width (nmeHandle); }
	/** @private */ private function nmeGetHeight():Int { return nme_bitmap_data_height (nmeHandle); }
	/** @private */ private function nmeGetTransparent():Bool { return nme_bitmap_data_get_transparent (nmeHandle); }
	
	
	
	// Native Methods
	
	
	
	private static var nme_bitmap_data_create = Loader.load("nme_bitmap_data_create", 5);
	private static var nme_bitmap_data_load = Loader.load("nme_bitmap_data_load", 2);
	private static var nme_bitmap_data_from_bytes = Loader.load("nme_bitmap_data_from_bytes", 2);
	private static var nme_bitmap_data_clear = Loader.load("nme_bitmap_data_clear", 2);
	private static var nme_bitmap_data_clone = Loader.load("nme_bitmap_data_clone", 1);
	private static var nme_bitmap_data_apply_filter = Loader.load("nme_bitmap_data_apply_filter", 5);
	private static var nme_bitmap_data_color_transform = Loader.load("nme_bitmap_data_color_transform", 3);
	private static var nme_bitmap_data_copy = Loader.load("nme_bitmap_data_copy", 5);
	private static var nme_bitmap_data_copy_channel = Loader.load("nme_bitmap_data_copy_channel", -1);
	private static var nme_bitmap_data_fill = Loader.load("nme_bitmap_data_fill", 4);
	private static var nme_bitmap_data_get_pixels = Loader.load("nme_bitmap_data_get_pixels", 2);
	private static var nme_bitmap_data_get_pixel = Loader.load("nme_bitmap_data_get_pixel", 3);
	private static var nme_bitmap_data_get_pixel32 = Loader.load("nme_bitmap_data_get_pixel32", 3);
	private static var nme_bitmap_data_get_pixel_rgba = Loader.load("nme_bitmap_data_get_pixel_rgba", 3);
	#if cpp
	private static var nme_bitmap_data_get_array = Loader.load("nme_bitmap_data_get_array", 3);
	#end
	private static var nme_bitmap_data_get_color_bounds_rect = Loader.load("nme_bitmap_data_get_color_bounds_rect", 5);
	private static var nme_bitmap_data_scroll = Loader.load("nme_bitmap_data_scroll", 3);
	private static var nme_bitmap_data_set_pixel = Loader.load("nme_bitmap_data_set_pixel", 4);
	private static var nme_bitmap_data_set_pixel32 = Loader.load("nme_bitmap_data_set_pixel32", 4);
	private static var nme_bitmap_data_set_pixel_rgba = Loader.load("nme_bitmap_data_set_pixel_rgba", 4);
	private static var nme_bitmap_data_set_bytes = Loader.load("nme_bitmap_data_set_bytes", 4);
	private static var nme_bitmap_data_set_format = Loader.load("nme_bitmap_data_set_format", 2);
	#if cpp
	private static var nme_bitmap_data_set_array = Loader.load("nme_bitmap_data_set_array", 3);
	private static var nme_bitmap_data_create_hardware_surface = Loader.load("nme_bitmap_data_create_hardware_surface", 1);
	private static var nme_bitmap_data_destroy_hardware_surface = Loader.load("nme_bitmap_data_destroy_hardware_surface", 1);
	#end
	private static var nme_bitmap_data_generate_filter_rect = Loader.load("nme_bitmap_data_generate_filter_rect", 3);
	private static var nme_render_surface_to_surface = Loader.load("nme_render_surface_to_surface", -1);
	private static var nme_bitmap_data_height = Loader.load("nme_bitmap_data_height", 1);
	private static var nme_bitmap_data_width = Loader.load("nme_bitmap_data_width", 1);
	private static var nme_bitmap_data_get_transparent = Loader.load("nme_bitmap_data_get_transparent", 1);
	private static var nme_bitmap_data_set_flags = Loader.load("nme_bitmap_data_set_flags", 1);
	private static var nme_bitmap_data_encode = Loader.load("nme_bitmap_data_encode", 3);
	private static var nme_bitmap_data_dump_bits = Loader.load("nme_bitmap_data_dump_bits", 1);
	private static var nme_bitmap_data_noise = Loader.load("nme_bitmap_data_noise", -1);
	
}


class OptimizedPerlin
{
	
	private static var P = [
		151,160,137,91,90,15,131,13,201,95,
		96,53,194,233,7,225,140,36,103,30,69,
		142,8,99,37,240,21,10,23,190,6,148,
		247,120,234,75,0,26,197,62,94,252,
		219,203,117,35,11,32,57,177,33,88,
		237,149,56,87,174,20,125,136,171,
		168,68,175,74,165,71,134,139,48,27,
		166,77,146,158,231,83,111,229,122,
		60,211,133,230,220,105,92,41,55,46,
		245,40,244,102,143,54,65,25,63,161,
		1,216,80,73,209,76,132,187,208,89,
		18,169,200,196,135,130,116,188,159,
		86,164,100,109,198,173,186,3,64,52,
		217,226,250,124,123,5,202,38,147,118,
		126,255,82,85,212,207,206,59,227,47,
		16,58,17,182,189,28,42,223,183,170,
		213,119,248,152,2,44,154,163,70,221,
		153,101,155,167,43,172,9,129,22,39,
		253,19,98,108,110,79,113,224,232,
		178,185,112,104,218,246,97,228,251,
		34,242,193,238,210,144,12,191,179,
		162,241,81,51,145,235,249,14,239,
		107,49,192,214,31,181,199,106,157,
		184,84,204,176,115,121,50,45,127,4,
		150,254,138,236,205,93,222,114,67,29,
		24,72,243,141,128,195,78,66,215,61,
		156,180,151,160,137,91,90,15,131,13,
		201,95,96,53,194,233,7,225,140,36,
		103,30,69,142,8,99,37,240,21,10,23,
		190,6,148,247,120,234,75,0,26,197,
		62,94,252,219,203,117,35,11,32,57,
		177,33,88,237,149,56,87,174,20,125,
		136,171,168,68,175,74,165,71,134,139,
		48,27,166,77,146,158,231,83,111,229,
		122,60,211,133,230,220,105,92,41,55,
		46,245,40,244,102,143,54,65,25,63,
		161,1,216,80,73,209,76,132,187,208,
		89,18,169,200,196,135,130,116,188,
		159,86,164,100,109,198,173,186,3,64,
		52,217,226,250,124,123,5,202,38,147,
		118,126,255,82,85,212,207,206,59,
		227,47,16,58,17,182,189,28,42,223,
		183,170,213,119,248,152,2,44,154,
		163,70,221,153,101,155,167,43,172,9,
		129,22,39,253,19,98,108,110,79,113,
		224,232,178,185,112,104,218,246,97,
		228,251,34,242,193,238,210,144,12,
		191,179,162,241,81,51,145,235,249,
		14,239,107,49,192,214,31,181,199,
		106,157,184,84,204,176,115,121,50,
		45,127,4,150,254,138,236,205,93,
		222,114,67,29,24,72,243,141,128,
		195,78,66,215,61,156,180
	];
	
	private var octaves:Int;
	
	private var aOctFreq:Array<Float>; // frequency per octave
	private var aOctPers:Array<Float>; // persistence per octave
	private var fPersMax:Float;// 1 / max persistence
	
	private var iXoffset:Float;
	private var iYoffset:Float;
	private var iZoffset:Float;
	
	private var baseFactor:Float;
	
	
	public function new(seed = 123, octaves = 4, falloff = 0.5)
	{
		baseFactor = 1 / 64;
		seedOffset(seed);
		octFreqPers(falloff);
	}
	
	
	public function fill(bitmap:BitmapData, _x:Float, _y:Float, _z:Float, ?_):Void
	{
		var baseX:Float;
		
		baseX = _x * baseFactor + iXoffset;
		_y = _y * baseFactor + iYoffset;
		_z = _z * baseFactor + iZoffset;

		var width:Int = bitmap.width;
		var height:Int = bitmap.height;
		
		var p = P;
		var octaves = octaves;
		var aOctFreq = aOctFreq;
		var aOctPers = aOctPers;
		
		for (py in 0...height)
		{
			_x = baseX;

			for (px in 0...width)
			{
				var s = 0.;
				
				for (i in 0...octaves)
				{
					var fFreq = aOctFreq[i];
					var fPers = aOctPers[i];

					var x = _x * fFreq;
					var y = _y * fFreq;
					var z = _z * fFreq;

					var xf = x - (x % 1);
					var yf = y - (y % 1);
					var zf = z - (z % 1);

					var X = Std.int(xf) & 255;
					var Y = Std.int(yf) & 255;
					var Z = Std.int(zf) & 255;

					x -= xf;
					y -= yf;
					z -= zf;

					var u = x * x * x * (x * (x*6 - 15) + 10);
					var v = y * y * y * (y * (y*6 - 15) + 10);
					var w = z * z * z * (z * (z*6 - 15) + 10);

					var A  = (p[X]) + Y;
					var AA = (p[A]) + Z;
					var AB = (p[A+1]) + Z;
					var B  = (p[X+1]) + Y;
					var BA = (p[B]) + Z;
					var BB = (p[B+1]) + Z;

					var x1 = x-1;
					var y1 = y-1;
					var z1 = z-1;

					var hash = (p[BB+1]) & 15;
					var g1 = ((hash&1) == 0 ? (hash<8 ? x1 : y1) : (hash<8 ? -x1 : -y1)) + ((hash&2) == 0 ? hash<4 ? y1 : ( hash==12 ? x1 : z1 ) : hash<4 ? -y1 : ( hash==14 ? -x1 : -z1 ));

					hash = (p[AB+1]) & 15;
					var g2 = ((hash&1) == 0 ? (hash<8 ? x  : y1) : (hash<8 ? -x  : -y1)) + ((hash&2) == 0 ? hash<4 ? y1 : ( hash==12 ? x  : z1 ) : hash<4 ? -y1 : ( hash==14 ? -x : -z1 ));

					hash = (p[BA+1]) & 15;
					var g3 = ((hash&1) == 0 ? (hash<8 ? x1 : y ) : (hash<8 ? -x1 : -y )) + ((hash&2) == 0 ? hash<4 ? y  : ( hash==12 ? x1 : z1 ) : hash<4 ? -y  : ( hash==14 ? -x1 : -z1 ));

					hash = (p[AA+1]) & 15;
					var g4 = ((hash&1) == 0 ? (hash<8 ? x  : y ) : (hash<8 ? -x  : -y )) + ((hash&2) == 0 ? hash<4 ? y  : ( hash==12 ? x  : z1 ) : hash<4 ? -y  : ( hash==14 ? -x  : -z1 ));

					hash = (p[BB]) & 15;
					var g5 = ((hash&1) == 0 ? (hash<8 ? x1 : y1) : (hash<8 ? -x1 : -y1)) + ((hash&2) == 0 ? hash<4 ? y1 : ( hash==12 ? x1 : z  ) : hash<4 ? -y1 : ( hash==14 ? -x1 : -z  ));

					hash = (p[AB]) & 15;
					var g6 = ((hash&1) == 0 ? (hash<8 ? x  : y1) : (hash<8 ? -x  : -y1)) + ((hash&2) == 0 ? hash<4 ? y1 : ( hash==12 ? x  : z  ) : hash<4 ? -y1 : ( hash==14 ? -x  : -z  ));

					hash = (p[BA]) & 15;
					var g7 = ((hash&1) == 0 ? (hash<8 ? x1 : y ) : (hash<8 ? -x1 : -y )) + ((hash&2) == 0 ? hash<4 ? y  : ( hash==12 ? x1 : z  ) : hash<4 ? -y  : ( hash==14 ? -x1 : -z  ));

					hash = (p[AA]) & 15;
					var g8 = ((hash&1) == 0 ? (hash<8 ? x  : y ) : (hash<8 ? -x  : -y )) + ((hash&2) == 0 ? hash<4 ? y  : ( hash==12 ? x  : z  ) : hash<4 ? -y  : ( hash==14 ? -x  : -z  ));

					g2 += u * (g1 - g2);
					g4 += u * (g3 - g4);
					g6 += u * (g5 - g6);
					g8 += u * (g7 - g8);

					g4 += v * (g2 - g4);
					g8 += v * (g6 - g8);

					s += ( g8 + w * (g4 - g8)) * fPers;
				}

				var color = Std.int( ( s * fPersMax + 1 ) * 128 );
				
				#if neko
				var pixel = { a: 0xFF, rgb: color };
				#else
				var pixel = 0xff000000 | color << 16 | color << 8 | color;
				#end

				bitmap.setPixel32( px, py, pixel);

				_x += baseFactor;
			}

			_y += baseFactor;
		}
	}
	
	
	private function octFreqPers(fPersistence)
	{	
		var fFreq:Float, fPers:Float;
		
		aOctFreq = [];
		aOctPers = [];
		fPersMax = 0;
		
		for (i in 0...octaves) {
			fFreq = Math.pow(2, i);
			fPers = Math.pow(fPersistence, i);
			fPersMax += fPers;
			aOctFreq.push(fFreq);
			aOctPers.push(fPers);
		}
		
		fPersMax = 1 / fPersMax;
	}
	
	
	private function seedOffset(iSeed:Int) {
		#if neko
		iXoffset = iSeed = Std.int((iSeed * 16807.) % 21474836);
		iYoffset = iSeed = Std.int((iSeed * 16807.) % 21474836);
		iZoffset = iSeed = Std.int((iSeed * 16807.) % 21474836);
		#else
		iXoffset = iSeed = Std.int((iSeed * 16807.) % 2147483647);
		iYoffset = iSeed = Std.int((iSeed * 16807.) % 2147483647);
		iZoffset = iSeed = Std.int((iSeed * 16807.) % 2147483647);
		#end
	}
	
}
