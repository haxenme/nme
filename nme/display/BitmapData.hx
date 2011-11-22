package nme.display;
#if (cpp || neko)


import haxe.io.Bytes;
import nme.geom.Rectangle;
import nme.geom.Point;
import nme.geom.Matrix;
import nme.geom.ColorTransform;
import nme.filters.BitmapFilter;
import nme.utils.ByteArray;
import nme.Loader;


/**
* @author   Hugh Sanderson
* @author   Russell Weir
* @todo getPixel, getPixel32 should be optimized to use library methods
*/
class BitmapData implements IBitmapDrawable
{
	
	public inline static var CLEAR = createColor(0, 0);
	public inline static var BLACK = createColor(0x000000);
	public inline static var WHITE = createColor(0x000000);
	public inline static var RED = createColor(0xff0000);
	public inline static var GREEN = createColor(0x00ff00);
	public inline static var BLUE = createColor(0x0000ff);
	public inline static var PNG = "png";
	public inline static var JPG = "jpg";
	
	public static var TRANSPARENT = 0x0001;
	public static var HARDWARE = 0x0002;
	public static var FORMAT_8888:Int = 0;
	public static var FORMAT_4444_PADDED:Int = 1; //Due to the iOS loader premultiplying alpha - you can't 
	public static var FORMAT_4444:Int = 2; //Placeholder - will switch this on when we use libpng for all
	
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
	
	
	public function createHardwareSurface()
	{
		nme_bitmap_data_create_hardware_surface(nmeHandle);
	}
	
	
	public function destroyHardwareSurface()
	{
		nme_bitmap_data_destroy_hardware_surface(nmeHandle);
	}
	
	
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
	
	
	public function nmeDrawToSurface(inSurface:Dynamic, matrix:Matrix, colorTransform:ColorTransform, blendMode:String, clipRect:Rectangle, smoothing:Bool):Void
	{
		// IBitmapDrawable interface...
		nme_render_surface_to_surface(inSurface, nmeHandle, matrix, colorTransform, blendMode, clipRect, smoothing);
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
	
	
	
	// Getters & Setters
	
	
	
	private function nmeGetRect():Rectangle { return new Rectangle (0, 0, width, height); }
	private function nmeGetWidth():Int { return nme_bitmap_data_width (nmeHandle); }
	private function nmeGetHeight():Int { return nme_bitmap_data_height (nmeHandle); }
	private function nmeGetTransparent():Bool { return nme_bitmap_data_get_transparent (nmeHandle); }
	
	
	
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
	
}


#else
typedef BitmapData = flash.display.BitmapData;
#end