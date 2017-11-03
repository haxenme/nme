package nme.bare;

import haxe.io.Bytes;
import nme.geom.Rectangle;
import nme.geom.Point;
import nme.geom.Matrix;
import nme.geom.ColorTransform;
import nme.utils.ByteArray;
import nme.Loader;
import nme.NativeHandle;
import nme.image.PixelFormat;

@:nativeProperty
class Surface
{
   public inline static var PNG = "png";
   public inline static var JPG = "jpg";

   public static var TRANSPARENT = 0x0001;
   public static var HARDWARE = 0x0002;


   public static var FLAG_NOREPEAT_NONPOT = 0x0001;
   public static var FLAG_FIXED_FORMAT = 0x0002;

   public static inline var CHANNEL_RED   = 0x0001;
   public static inline var CHANNEL_GREEN = 0x0002;
   public static inline var CHANNEL_BLUE  = 0x0004;
   public static inline var CHANNEL_ALPHA = 0x0008;

   public static inline var FLOAT_UNSCALED     = 0x0000;
   public static inline var FLOAT_ZERO_MEAN    = 0x0001;
   public static inline var FLOAT_128_MEAN     = 0x0002;
   public static inline var FLOAT_UNIT_SCALE   = 0x0004;
   public static inline var FLOAT_STD_SCALE    = 0x0008;
   public static inline var FLOAT_SWIZZLE_RGB  = 0x0010;

   // zero mean, std scale
   public static inline var FLOAT_NORM       = 0x0009;
   // add 128, * 255
   public static inline var FLOAT_EXPAND     = 0x0006;

   public var height(get_height, null):Int;
   public var rect(get_rect, null):Rectangle;
   public var transparent(get_transparent, null):Bool;
   public var width(get_width, null):Int;
   public var format(get, set):Int;
   public var premultipliedAlpha(get_premultipliedAlpha, set_premultipliedAlpha):Bool;
   public var nmeHandle:NativeHandle;
   

   public function new(inWidth:Int, inHeight:Int, inPixelFormat:Int, ?inFillRgb:Int)
   {
      if (inWidth>0 && inHeight>0 && inPixelFormat!=PixelFormat.pfNone)
         nmeHandle = nme_bitmap_data_create(inWidth, inHeight, inPixelFormat, inFillRgb);
   }


   public static function createUInt16(width:Int, height:Int) : Surface
   {
      return new Surface(width, height, PixelFormat.pfUInt16, 0);
   }


   public static function createUInt32(width:Int, height:Int) : Surface
   {
      return new Surface(width, height, PixelFormat.pfUInt32, 0);
   }



   public function clear(color:Int):Void 
   {
      nme_bitmap_data_clear(nmeHandle, color);
   }

   public function clone():Surface 
   {
      var bm = new Surface(0, 0, PixelFormat.pfNone);
      bm.nmeHandle = nme_bitmap_data_clone(nmeHandle);
      return bm;
   }

   public function colorTransform(rect:Rectangle, colorTransform:ColorTransform):Void 
   {
      nme_bitmap_data_color_transform(nmeHandle, rect, colorTransform);
   }

   public function copyChannel(sourceBitmapData:Surface, sourceRect:Rectangle, destPoint:Point, inSourceChannel:Int, inDestChannel:Int):Void 
   {
      nme_bitmap_data_copy_channel(sourceBitmapData.nmeHandle, sourceRect, nmeHandle, destPoint, inSourceChannel, inDestChannel);
   }

   public function copyPixels(sourceBitmapData:Surface, sourceRect:Rectangle, destPoint:Point, ?alphaBitmapData:Surface, ?alphaPoint:Point, mergeAlpha:Bool = false):Void 
   {
      nme_bitmap_data_copy(sourceBitmapData.nmeHandle, sourceRect, nmeHandle, destPoint, mergeAlpha);
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
      nme_bitmap_data_dispose(nmeHandle);
      nmeHandle = null;
   }

   public function dumpBits():Void 
   {
      nme_bitmap_data_dump_bits(nmeHandle);
   }

   public function encode(inFormat:String, inQuality:Float = 0.9):ByteArray 
   {
      return nme_bitmap_data_encode(nmeHandle, inFormat, inQuality);
   }


   public function fillRect(rect:Rectangle, inColour:Int):Void 
   {
      var a = inColour >>> 24;
      var c = inColour & 0xffffff;
      nme_bitmap_data_fill(nmeHandle, rect, c, a);
   }

   public function fillRectEx(rect:Rectangle, inColour:Int, inAlpha:Int = 255):Void 
   {
      nme_bitmap_data_fill(nmeHandle, rect, inColour, inAlpha);
   }

   
   public function floodFill(x:Int, y:Int, color:Int):Void
   {
	  nme_bitmap_data_flood_fill(nmeHandle, x, y, color);
   }

   
   public function getColorBoundsRect(mask:Int, color:Int, findColor:Bool = true):Rectangle 
   {
      var result = new Rectangle();
      nme_bitmap_data_get_color_bounds_rect(nmeHandle, mask, color, findColor, result);
      return result;
   }

   public function getPixel(x:Int, y:Int):Int 
   {
      return nme_bitmap_data_get_pixel(nmeHandle, x, y);
   }

   public function getPixel32(x:Int, y:Int):Int 
   {
      return nme_bitmap_data_get_pixel32(nmeHandle, x, y);
   }

   public function getPixels(rect:Rectangle):ByteArray 
   {
      var result:ByteArray = nme_bitmap_data_get_pixels(nmeHandle, rect);
      if (result != null) result.position = result.length;
      return result;
   }

   public function getVector(rect:Rectangle):Array<Int> 
   {
      var pixels = Std.int(rect.width * rect.height);

      if (pixels < 1) return [];

      var result = new Array<Int>();
      result[pixels - 1] = 0;

      #if cpp
      nme_bitmap_data_get_array(nmeHandle, rect, result);
      #else
      var bytes:ByteArray = nme_bitmap_data_get_pixels(nmeHandle, rect);
      bytes.position = 0;
      for(i in 0...pixels) result[i] = bytes.readInt();
      #end

      return result;
   }

   public static function load(inFilename:String, format:Int = 0):Surface 
   {
      var result = new Surface(0, 0, PixelFormat.pfNone);
      result.nmeHandle = nme_bitmap_data_load(inFilename, format);
      return result;
   }

   public static function loadFromBytes(inBytes:ByteArray, ?inRawAlpha:ByteArray):Surface 
   {
      var result = new Surface(0, 0, PixelFormat.pfNone);
      result.nmeLoadFromBytes(inBytes, inRawAlpha);
      return result;
   }

   public static function loadFromHaxeBytes(inBytes:Bytes, ?inRawAlpha:Bytes)  : Surface
   {
      return loadFromBytes(ByteArray.fromBytes(inBytes), inRawAlpha == null ? null : ByteArray.fromBytes(inRawAlpha));
   }


   public function nmeDrawToSurface(inSurface:Dynamic, matrix:Matrix, colorTransform:ColorTransform, blendMode:String, clipRect:Rectangle, smoothing:Bool):Void
   {
      // IBitmapDrawable interface...
      var blendIndex = 0;
      nme_render_surface_to_surface(inSurface, nmeHandle, matrix, colorTransform, blendIndex, clipRect, smoothing);
   }
   
   private inline function nmeLoadFromBytes(inBytes:ByteArray, ?inRawAlpha:ByteArray):Void 
   {
      nmeHandle = nme_bitmap_data_from_bytes(inBytes, inRawAlpha);
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

   public function getFlags():Int 
   {
      return nme_bitmap_data_get_flags(nmeHandle);
   }


   public function setPixel(inX:Int, inY:Int, inColour:Int):Void 
   {
      nme_bitmap_data_set_pixel(nmeHandle, inX, inY, inColour);
   }

   public function setPixel32(inX:Int, inY:Int, inColour:Int):Void 
   {
      nme_bitmap_data_set_pixel32(nmeHandle, inX, inY, inColour);
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

      if (inPixels.length < count) return;

      #if cpp
      nme_bitmap_data_set_array(nmeHandle, rect, inPixels);
      #else
      var bytes = new ByteArray();
      for(i in 0...count)
         bytes.writeInt(inPixels[i]);
      nme_bitmap_data_set_bytes(nmeHandle, rect, bytes, 0);
      #end
   }

   public function getFloats32(dataHandle:Dynamic, dataOffset:Int, dataStride:Int,
           pixelFormat:Int, transform:Int, subSample:Int = 1)
   {
      nme_bitmap_data_get_floats32(nmeHandle,dataHandle, dataOffset, dataStride, pixelFormat, transform, subSample);
   }


   public function setFloats32(dataHandle:Dynamic, dataOffset:Int, dataStride:Int,
           pixelFormat:Int, transform:Int, expand:Int = 1)
   {
      nme_bitmap_data_set_floats32(nmeHandle,dataHandle, dataOffset, dataStride, pixelFormat, transform, expand);
   }

   public function setFormat(format:Int,inConvert=true) 
   {
      nme_bitmap_data_set_format(nmeHandle, format, inConvert);
   }

   inline public function set_format(format:Int) : Int
   {
      setFormat(format);
      return format;
   }

   public function get_format() : Int
   {
      return nme_bitmap_data_get_format(nmeHandle);
   }




   public function noise(randomSeed:Int, low:Int = 0, high:Int = 255, channelOptions:Int = 7, grayScale:Bool = false) 
   {
      nme_bitmap_data_noise(nmeHandle, randomSeed, low, high, channelOptions, grayScale);
   }

   // Getters & Setters
   private function get_rect():Rectangle { return new Rectangle(0, 0, width, height); }
   private function get_width():Int { return nme_bitmap_data_width(nmeHandle); }
   private function get_height():Int { return nme_bitmap_data_height(nmeHandle); }
   private function get_transparent():Bool { return nme_bitmap_data_get_transparent(nmeHandle); }
   private function get_premultipliedAlpha():Bool { return nme_bitmap_data_get_prem_alpha(nmeHandle); }
   private function set_premultipliedAlpha(inVal:Bool):Bool
   {
      nme_bitmap_data_set_prem_alpha(nmeHandle,inVal);
      return inVal;
   }

   // Native Methods
   private static var nme_bitmap_data_create = Loader.load("nme_bitmap_data_create", 4);
   private static var nme_bitmap_data_load = Loader.load("nme_bitmap_data_load", 2);
   private static var nme_bitmap_data_from_bytes = Loader.load("nme_bitmap_data_from_bytes", 2);
   private static var nme_bitmap_data_clear = Loader.load("nme_bitmap_data_clear", 2);
   private static var nme_bitmap_data_clone = Loader.load("nme_bitmap_data_clone", 1);
   private static var nme_bitmap_data_apply_filter = Loader.load("nme_bitmap_data_apply_filter", 5);
   private static var nme_bitmap_data_color_transform = Loader.load("nme_bitmap_data_color_transform", 3);
   private static var nme_bitmap_data_copy = Loader.load("nme_bitmap_data_copy", 5);
   private static var nme_bitmap_data_copy_channel = nme.PrimeLoader.load("nme_bitmap_data_copy_channel", "ooooiiv");
   private static var nme_bitmap_data_fill = Loader.load("nme_bitmap_data_fill", 4);
   private static var nme_bitmap_data_get_pixels = Loader.load("nme_bitmap_data_get_pixels", 2);
   private static var nme_bitmap_data_get_pixel = Loader.load("nme_bitmap_data_get_pixel", 3);
   private static var nme_bitmap_data_get_pixel32 = Loader.load("nme_bitmap_data_get_pixel32", 3);
   #if cpp
   private static var nme_bitmap_data_get_array = Loader.load("nme_bitmap_data_get_array", 3);
   #end
   private static var nme_bitmap_data_get_color_bounds_rect = Loader.load("nme_bitmap_data_get_color_bounds_rect", 5);
   private static var nme_bitmap_data_scroll = Loader.load("nme_bitmap_data_scroll", 3);
   private static var nme_bitmap_data_set_pixel = Loader.load("nme_bitmap_data_set_pixel", 4);
   private static var nme_bitmap_data_set_pixel32 = Loader.load("nme_bitmap_data_set_pixel32", 4);
   private static var nme_bitmap_data_set_pixel_rgba = Loader.load("nme_bitmap_data_set_pixel_rgba", 4);
   private static var nme_bitmap_data_set_bytes = Loader.load("nme_bitmap_data_set_bytes", 4);
   private static var nme_bitmap_data_set_format = Loader.load("nme_bitmap_data_set_format", 3);
   private static var nme_bitmap_data_get_format = Loader.load("nme_bitmap_data_get_format", 1);
   #if cpp
   private static var nme_bitmap_data_set_array = Loader.load("nme_bitmap_data_set_array", 3);
   #end
   private static var nme_bitmap_data_create_hardware_surface = Loader.load("nme_bitmap_data_create_hardware_surface", 1);
   private static var nme_bitmap_data_destroy_hardware_surface = Loader.load("nme_bitmap_data_destroy_hardware_surface", 1);
   private static var nme_bitmap_data_generate_filter_rect = Loader.load("nme_bitmap_data_generate_filter_rect", 3);
   private static var nme_render_surface_to_surface = nme.PrimeLoader.load("nme_render_surface_to_surface", "ooooiobv");
   private static var nme_bitmap_data_height = Loader.load("nme_bitmap_data_height", 1);
   private static var nme_bitmap_data_width = Loader.load("nme_bitmap_data_width", 1);
   private static var nme_bitmap_data_get_transparent = Loader.load("nme_bitmap_data_get_transparent", 1);
   private static var nme_bitmap_data_set_flags = Loader.load("nme_bitmap_data_set_flags", 2);
   private static var nme_bitmap_data_get_flags = Loader.load("nme_bitmap_data_get_flags", 1);
   private static var nme_bitmap_data_encode = Loader.load("nme_bitmap_data_encode", 3);
   private static var nme_bitmap_data_dump_bits = Loader.load("nme_bitmap_data_dump_bits", 1);
   private static var nme_bitmap_data_dispose = Loader.load("nme_bitmap_data_dispose", 1);
   private static var nme_bitmap_data_noise = Loader.load("nme_bitmap_data_noise", -1);
   private static var nme_bitmap_data_flood_fill = Loader.load("nme_bitmap_data_flood_fill", 4);
   private static var nme_bitmap_data_get_prem_alpha = Loader.load("nme_bitmap_data_get_prem_alpha", 1);
   private static var nme_bitmap_data_set_prem_alpha = Loader.load("nme_bitmap_data_set_prem_alpha", 2);
   private static var nme_bitmap_data_get_floats32 = nme.PrimeLoader.load("nme_bitmap_data_get_floats32", "ooiiiiiv");
   private static var nme_bitmap_data_set_floats32 = nme.PrimeLoader.load("nme_bitmap_data_set_floats32", "ooiiiiiv");
}

