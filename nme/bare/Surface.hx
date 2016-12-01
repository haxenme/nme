package nme.bare;

import haxe.io.Bytes;
import nme.geom.Rectangle;
import nme.geom.Point;
import nme.geom.Matrix;
import nme.geom.ColorTransform;
import nme.utils.ByteArray;
import nme.Loader;

typedef BitmapInt32 = Int;

@:nativeProperty
class Surface
{
   public inline static var PNG = "png";
   public inline static var JPG = "jpg";

   public static var TRANSPARENT = 0x0001;
   public static var HARDWARE = 0x0002;
   public static var FORMAT_8888:Int = 0;
   public static var FORMAT_4444:Int = 1; //16 bit with alpha channel
   public static var FORMAT_565:Int = 2;  //16 bit 565 without alpha
   public static var FORMAT_LUMA:Int = 3;  //8 bit, luma
   public static var FORMAT_LUMA_ALPHA:Int = 4;  //16 bit, luma + alpha
   public static var FORMAT_RGB:Int = 5;  //24 bit, rgb
   public static var FORMAT_BGRPremA:Int = 7;  //Premultipled alpha
   public static var FORMAT_UINT16:Int = 8;  // 16-bit channel
   public static var FORMAT_UINT32:Int = 9;  // 32-bit channel
   public static var FORMAT_ALPHA:Int = 10;  // 8-bit channel

   public var height(get_height, null):Int;
   public var rect(get_rect, null):Rectangle;
   public var transparent(get_transparent, null):Bool;
   public var width(get_width, null):Int;
   public var format(get, set):Int;
   public var premultipliedAlpha(get_premultipliedAlpha, set_premultipliedAlpha):Bool;
   public var nmeHandle:Dynamic;
   

   public function new(inWidth:Int, inHeight:Int, inTransparent:Bool = true, ?inFillARGB:BitmapInt32, ?inInternalFormat:Null<Int>)
   {
      var fill_col:Int;
      var fill_alpha:Int;

      if (inFillARGB == null)
      {
         fill_col = 0xffffff;
         fill_alpha = 0xff;
      }
      else 
      {
         fill_col = inFillARGB & 0xffffff;
         fill_alpha = inFillARGB >>> 24;
      }

      nmeHandle = null;
      if (inWidth >= 1 && inHeight >= 1) 
      {
         var flags = HARDWARE;

         if (inTransparent || inInternalFormat==FORMAT_ALPHA)
            flags |= TRANSPARENT;
         else
            fill_alpha = 0xff;

         nmeHandle = nme_bitmap_data_create(inWidth, inHeight, flags, fill_col, fill_alpha, inInternalFormat);
      }
   }


   public static function createUInt16(width:Int, height:Int) : Surface
   {
      return new Surface(width, height, false, 0, FORMAT_UINT16);
   }


   public static function createUInt32(width:Int, height:Int) : Surface
   {
      return new Surface(width, height, false, 0, FORMAT_UINT32);
   }



   public function clear(color:Int):Void 
   {
      nme_bitmap_data_clear(nmeHandle, color);
   }

   public function clone():Surface 
   {
      var bm = new Surface(0, 0, transparent);
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


   public function fillRect(rect:Rectangle, inColour:BitmapInt32):Void 
   {
      var a = inColour >>> 24;
      var c = inColour & 0xffffff;
      nme_bitmap_data_fill(nmeHandle, rect, c, a);
   }

   public function fillRectEx(rect:Rectangle, inColour:Int, inAlpha:Int = 255):Void 
   {
      nme_bitmap_data_fill(nmeHandle, rect, inColour, inAlpha);
   }

   
   public function floodFill(x:Int, y:Int, color:BitmapInt32):Void
   {
	  nme_bitmap_data_flood_fill(nmeHandle, x, y, color);
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
      var result = new Surface(0, 0);
      result.nmeHandle = nme_bitmap_data_load(inFilename, format);
      return result;
   }

   public static function loadFromBytes(inBytes:ByteArray, ?inRawAlpha:ByteArray):Surface 
   {
      var result = new Surface(0, 0);
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
      nme_render_surface_to_surface(inSurface, nmeHandle, matrix, colorTransform, blendMode, clipRect, smoothing);
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

   public function setPixel(inX:Int, inY:Int, inColour:Int):Void 
   {
      nme_bitmap_data_set_pixel(nmeHandle, inX, inY, inColour);
   }

   public function setPixel32(inX:Int, inY:Int, inColour:BitmapInt32):Void 
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

   public function setFormat(format:Int) 
   {
      nme_bitmap_data_set_format(nmeHandle, format);
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
   private static var nme_bitmap_data_create = Loader.load("nme_bitmap_data_create", -1);
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
   private static var nme_bitmap_data_get_format = Loader.load("nme_bitmap_data_get_format", 1);
   #if cpp
   private static var nme_bitmap_data_set_array = Loader.load("nme_bitmap_data_set_array", 3);
   #end
   private static var nme_bitmap_data_create_hardware_surface = Loader.load("nme_bitmap_data_create_hardware_surface", 1);
   private static var nme_bitmap_data_destroy_hardware_surface = Loader.load("nme_bitmap_data_destroy_hardware_surface", 1);
   private static var nme_bitmap_data_generate_filter_rect = Loader.load("nme_bitmap_data_generate_filter_rect", 3);
   private static var nme_render_surface_to_surface = Loader.load("nme_render_surface_to_surface", -1);
   private static var nme_bitmap_data_height = Loader.load("nme_bitmap_data_height", 1);
   private static var nme_bitmap_data_width = Loader.load("nme_bitmap_data_width", 1);
   private static var nme_bitmap_data_get_transparent = Loader.load("nme_bitmap_data_get_transparent", 1);
   private static var nme_bitmap_data_set_flags = Loader.load("nme_bitmap_data_set_flags", 2);
   private static var nme_bitmap_data_encode = Loader.load("nme_bitmap_data_encode", 3);
   private static var nme_bitmap_data_dump_bits = Loader.load("nme_bitmap_data_dump_bits", 1);
   private static var nme_bitmap_data_dispose = Loader.load("nme_bitmap_data_dispose", 1);
   private static var nme_bitmap_data_noise = Loader.load("nme_bitmap_data_noise", -1);
   private static var nme_bitmap_data_flood_fill = Loader.load("nme_bitmap_data_flood_fill", 4);
   private static var nme_bitmap_data_get_prem_alpha = Loader.load("nme_bitmap_data_get_prem_alpha", 1);
   private static var nme_bitmap_data_set_prem_alpha = Loader.load("nme_bitmap_data_set_prem_alpha", 2);
}

