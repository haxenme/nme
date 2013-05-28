package native.display;
#if (cpp || neko)

import haxe.io.Bytes;
import native.geom.Rectangle;
import native.geom.Point;
import native.geom.Matrix;
import native.geom.ColorTransform;
import native.filters.BitmapFilter;
import native.utils.ByteArray;
import native.Loader;
#if (haxe3 && (!neko || !neko_v1))
typedef BitmapInt32 = Int;
#else
import nme.display.BitmapInt32;
#end

#if openfl @:autoBuild(openfl.Assets.embedBitmap()) #end
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

   public var height(get_height, null):Int;
   public var rect(get_rect, null):Rectangle;
   public var transparent(get_transparent, null):Bool;
   public var width(get_width, null):Int;
   
   private var nmeTransparent:Bool;

   /** @private */ public var nmeHandle:Dynamic;
   public function new(inWidth:Int, inHeight:Int, inTransparent:Bool = true, ?inFillRGBA:BitmapInt32, ?inGPUMode:Null<Bool>) 
   {
      var fill_col:Int;
      var fill_alpha:Int;
      nmeTransparent = inTransparent;

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

         if (inTransparent) flags |= TRANSPARENT;

         nmeHandle = nme_bitmap_data_create(inWidth, inHeight, flags, fill_col, fill_alpha, inGPUMode);
      }
   }

   public function applyFilter(sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point, filter:BitmapFilter):Void 
   {
      nme_bitmap_data_apply_filter(nmeHandle, sourceBitmapData.nmeHandle, sourceRect, destPoint, filter);
   }

   public function clear(color:Int):Void 
   {
      nme_bitmap_data_clear(nmeHandle, color);
   }

   public function clone():BitmapData 
   {
      var bm = new BitmapData(0, 0, transparent);
      bm.nmeHandle = nme_bitmap_data_clone(nmeHandle);
      return bm;
   }

   public function colorTransform(rect:Rectangle, colorTransform:ColorTransform):Void 
   {
      nme_bitmap_data_color_transform(nmeHandle, rect, colorTransform);
   }

   public function copyChannel(sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point, inSourceChannel:Int, inDestChannel:Int):Void 
   {
      nme_bitmap_data_copy_channel(sourceBitmapData.nmeHandle, sourceRect, nmeHandle, destPoint, inSourceChannel, inDestChannel);
   }

   public function copyPixels(sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point, ?alphaBitmapData:BitmapData, ?alphaPoint:Point, mergeAlpha:Bool = false):Void 
   {
      nme_bitmap_data_copy(sourceBitmapData.nmeHandle, sourceRect, nmeHandle, destPoint, mergeAlpha);
   }

   public static inline function createColor(inRGB:Int, inAlpha:Int = 0xFF):BitmapInt32 
   {
      #if (neko && (!haxe3 || neko_v1))
      return { rgb: inRGB, a: inAlpha };
      #else
      return inRGB |(inAlpha << 24);
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

   public function draw(source:IBitmapDrawable, matrix:Matrix = null, colorTransform:ColorTransform = null, blendMode:BlendMode = null, clipRect:Rectangle = null, smoothing:Bool = false):Void 
   {
      source.nmeDrawToSurface(nmeHandle, matrix, colorTransform, Std.string(blendMode), clipRect, smoothing);
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
      #if (neko && (!haxe3 || neko_v1))
      return v.a;
      #else
      return v >>> 24;
      #end
   }

   public static inline function extractColor(v:BitmapInt32):Int 
   {
      #if (neko && (!haxe3 || neko_v1))
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

   static inline function sameValue(a:BitmapInt32, b:BitmapInt32)
   {
      #if (neko && (!haxe3 || neko_v1))
      return a.rgb == b.rgb && a.a == b.a;
      #else
      return a==b;
      #end
   }
   
   public function floodFill(x:Int, y:Int, color:BitmapInt32):Void
   {
	  nme_bitmap_data_flood_fill(nmeHandle, x, y, color);
   }

   /**
    * Flips an ARGB pixel value to BGRA or vice-versa
    * @param	pix4 a 4-byte pixel value in AARRGGBB or BBGGRRAA format
    * @return   pix4 flipped-endian format
    */
   
   public static inline function flip_pixel4(pix4:Int):Int{
	   return (pix4       & 0xFF) << 24 |	//4th byte --> 1st byte
			  (pix4 >>  8 & 0xFF) << 16 |	//3rd byte --> 2nd byte
			  (pix4 >> 16 & 0xFF) <<  8 |	//2nd byte --> 3rd byte
			  (pix4 >> 24 & 0xFF);       	//1st byte --> 4th byte
   }
   
   /**
    * Tests pixel values in an image against a specified threshold and sets pixels that pass the test to new color values.
    * @param	sourceBitmapData input bitmap data. Source can be different BitmapData or can refer to current BitmapData. 
    * @param	sourceRect rectangle that defines area of source image to use as input. 
    * @param	destPoint point within destination image (current BitmapData) corresponding to upper-left corner of source rectangle. 
    * @param	operation one of these strings: "<", "<=", ">", ">=", "==", "!="
    * @param	threshold value each pixel is tested against to see if it meets or exceeds the threshhold.
    * @param	color color value a pixel is set to if threshold test succeeds.
    * @param	mask mask used to isolate a color component. 
    * @param	copySource If true, pixel values from source image are copied to destination when threshold test fails. If false, source image is not copied when threshold test fails.
    * @return
    */
   
	public function threshold(sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point, operation:String, threshold:Int, color:Int = 0x00000000, mask:Int = 0xFFFFFFFF, copySource:Bool = false):Int {
		
		//Quick check to see if we can do this with an optimized faster case
		if (sourceBitmapData == this && sourceRect.equals(rect) && destPoint.x==0 && destPoint.y==0) {
			return _self_threshold(operation, threshold, color, mask);
		}
		
		var sx:Int = Std.int(sourceRect.x);
		var sy:Int = Std.int(sourceRect.y);
		var sw:Int = Std.int(sourceBitmapData.width);
		var sh:Int = Std.int(sourceBitmapData.height);
		
		var dx:Int = Std.int(destPoint.x);
		var dy:Int = Std.int(destPoint.y);
		
		var bw:Int = width - sw - dx;
		var bh:Int = height - sh - dy;

		var dw:Int = (bw < 0) ? sw + (width - sw - dx) : sw;
		var dh:Int = (bw < 0) ? sh + (height - sh - dy) : sh;
		
		var hits:Int = 0;
	
		//flip endian-ness since this function's guts needs BGRA instead of RGBA
		threshold = flip_pixel4(threshold);
		color = flip_pixel4(color);
	
		//access the pixel data faster via raw bytes
		
		//Calculate how many bytes we need
		var canvas_mem:Int = (sw * sh) * 4;
		var source_mem:Int = 0;
		if(copySource){
			source_mem = (sw * sh) * 4;
			//for storing both bitmaps in one ByteArray
		}
		var total_mem:Int = (canvas_mem + source_mem);
		var mem:ByteArray = new ByteArray();
		mem.setLength(total_mem);
		
		//write pixels into RAM
		mem.position = 0;
		var bd1:BitmapData = sourceBitmapData.clone();
		mem.writeBytes(bd1.getPixels(sourceRect));
		mem.position = canvas_mem;
		if(copySource){
			var bd2:BitmapData = sourceBitmapData.clone();
			mem.writeBytes(bd2.getPixels(sourceRect));
			}
		
		mem.position = 0;
		
		//Select the memory space (just once)
		Memory.select(mem);
		
		var thresh_mask:Int = cast threshold & mask;
		
		//bound from 0...dw/dh to avoid unecessary calculations and return correct hits value
		for (yy in 0...dh) {
			for (xx in 0...dw) {
				var pos:Int = ((xx + sx) + (yy + sy) * sw) * 4;
				var pixelValue = Memory.getI32(pos);
				var pix_mask:Int = cast pixelValue & mask;
			
				var i:Int = ucompare(pix_mask, thresh_mask);
				var test:Bool = false;
					 if (operation == "==") { test = i == 0; }
				else if (operation == "<") { test = i == -1;}
				else if (operation == ">") { test = i == 1; }
				else if (operation == "!=") { test = i != 0; }
				else if (operation == "<=") { test = i == 0 || i == -1; }
				else if (operation == ">=") { test = i == 0 || i == 1; }
				if(test){
					Memory.setI32(pos, color);
					hits++;
				}else if (copySource) {
					var source_color = Memory.getI32(canvas_mem+pos);
					Memory.setI32(pos, source_color);
				}
			}
		}		
	mem.position = 0;	
	bd1.setPixels(sourceRect, mem);			//draw to our temp buffer
	copyPixels(bd1, bd1.rect, destPoint);	//draw to this bitmapdata at offset point
	Memory.select(null);
	return hits;	//# of pixels changed
   }
   
   //******Replaces Int32.ucompare()******//
	
	/**
	 * Compare 2 integers, byte-for-byte (unsigned mode)
	 * @param	n1	an integer
	 * @param	n2	another integer
	 * @return	0 if n1 == n2, 1 if n1 > n2, -1 if n1 < n2
	 */
	
   static public function ucompare(n1:Int, n2:Int) : Int {
        var tmp1 : Int;
        var tmp2 : Int;
		
		//For example, 
			//tmp1 = 0xFF3D76BC;
			//tmp2 = 0xFF3D76AA;
			
        //Int has 32 bits - 4 bytes (except neko 1.8)

        //compare first - "head" bytes
        tmp1 = (n1 >> 24) & 0x000000FF; //shift integers by 24 bits right for this purpose, so only head bytes left (0xFF)
        tmp2 = (n2 >> 24) & 0x000000FF;
        if( tmp1 != tmp2 ){
            //if head bytes are not equal, we can already know, which one is bigger
            return (tmp1 > tmp2 ? 1 : -1);

        //compare second byte
        }else{
            tmp1 = (n1 >> 16) & 0x000000FF; //tmp1 now contains 0x3D
            tmp2 = (n2 >> 16) & 0x000000FF; //tmp2 now contains 0x3D

            if( tmp1 != tmp2 ){
                return (tmp1 > tmp2 ? 1 : -1);

            //compare third byte
            }else{

                tmp1 = (n1 >> 8) & 0x000000FF; //tmp1 now contains 0x76
                tmp2 = (n2 >> 8) & 0x000000FF; //tmp2 now contains 0x76

                if( tmp1 != tmp2 ){
                    return (tmp1 > tmp2 ? 1 : -1);

                //compare last byte
                }else{
                    tmp1 = n1 & 0x000000FF; //tmp1 now contains 0xBC
                    tmp2 = n2 & 0x000000FF; //tmp2 now contains 0xAA

                    if( tmp1 != tmp2 ){
                        return (tmp1 > tmp2 ? 1 : -1);

                    //numbers are equal (n1 == n2)
                    }else{
                        return 0;
                    }
                }
            }
        }
    }
   
	//******END EXTRACTED SECTION******//
	
   /**
    * Fast version for when you're not messing with multiple thingies
    * @param	operation
    * @param	threshold
    * @param	color
    * @param	mask
    * @param	copySource
    * @return
    */
   
	public function _self_threshold(operation:String, threshold:Int, color:Int = 0x00000000, mask:Int = 0xFFFFFFFF):Int {
		var hits:Int = 0;
	
		//flip endian-ness since this function's guts needs BGRA instead of RGBA
		threshold = flip_pixel4(threshold);
		color = flip_pixel4(color);
		
		//access the pixel data faster via raw bytes
		var mem:ByteArray = new ByteArray();
		//32bit integer = 4 bytes
		mem.setLength((width * height) * 4);
		
		//write pixels into RAM
		var mem:ByteArray = getPixels(rect);
		mem.position = 0;
		
		//Select the memory space (just once)
		Memory.select(mem);
		
		var thresh_mask:Int = cast threshold & mask;
		
		for (yy in 0...height) {
			var width_yy:Int = width * yy;
			for (xx in 0...width) {
				var pos:Int = (width_yy + xx) * 4;
				var pixelValue = Memory.getI32(pos);
				var pix_mask:Int = cast pixelValue & mask;
			
				var i:Int = ucompare(pix_mask, thresh_mask);
				var test:Bool = false;
					 if (operation == "==") { test = i == 0; }
				else if (operation == "<") { test = i == -1;}
				else if (operation == ">") { test = i == 1; }
				else if (operation == "!=") { test = i != 0; }
				else if (operation == "<=") { test = i == 0 || i == -1; }
				else if (operation == ">=") { test = i == 0 || i == 1; }
				if(test){
					Memory.setI32(pos, color);
					hits++;
				}
			}
		}
	mem.position = 0;
	setPixels(rect, mem);
	Memory.select(null);
	return hits;
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
      #if (neko && (!haxe3 || neko_v1))
      return nme_bitmap_data_get_pixel_rgba(nmeHandle, x, y);
      #else
      return nme_bitmap_data_get_pixel32(nmeHandle, x, y);
      #end
   }

   public function getPixels(rect:Rectangle):ByteArray 
   {
      var result:ByteArray = nme_bitmap_data_get_pixels(nmeHandle, rect);
      if (result != null) result.position = result.length;
      return result;
   }

   inline public static function getRGBAPixels(bitmapData:BitmapData):ByteArray 
   {
      var p = bitmapData.getPixels(new Rectangle(0, 0, bitmapData.width, bitmapData.height));
      var num = bitmapData.width * bitmapData.height;

      for(i in 0...num) 
      {
         var alpha = p[i * 4];
         var red = p[i * 4 + 1];
         var green = p[i * 4 + 2];
         var blue = p[i * 4 + 3];

         p[i * 4] = red;
         p[i * 4 + 1] = green;
         p[i * 4 + 2] = blue;
         p[i * 4 + 3] = alpha;
      }

      return p;
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

   public static function load(inFilename:String, format:Int = 0):BitmapData 
   {
      var result = new BitmapData(0, 0);
      result.nmeHandle = nme_bitmap_data_load(inFilename, format);
      return result;
   }

   public static function loadFromBytes(inBytes:ByteArray, ?inRawAlpha:ByteArray):BitmapData 
   {
      var result = new BitmapData(0, 0);
	  result.nmeLoadFromBytes(inBytes, inRawAlpha);
      return result;
   }

   public static function loadFromHaxeBytes(inBytes:Bytes, ?inRawAlpha:Bytes) 
   {
      return loadFromBytes(ByteArray.fromBytes(inBytes), inRawAlpha == null ? null : ByteArray.fromBytes(inRawAlpha));
   }

   public function lock() 
   {
      // Handled internally...
   }

   /** @private */ public function nmeDrawToSurface(inSurface:Dynamic, matrix:Matrix, colorTransform:ColorTransform, blendMode:String, clipRect:Rectangle, smoothing:Bool):Void {
      // IBitmapDrawable interface...
      nme_render_surface_to_surface(inSurface, nmeHandle, matrix, colorTransform, blendMode, clipRect, smoothing);
   }
   
   private inline function nmeLoadFromBytes(inBytes:ByteArray, ?inRawAlpha:ByteArray):Void 
   {
      nmeHandle = nme_bitmap_data_from_bytes(inBytes, inRawAlpha);
   }

   public function perlinNoise(baseX:Float, baseY:Float, numOctaves:Int, randomSeed:Int, stitch:Bool, fractalNoise:Bool, channelOptions:Int = 7, grayScale:Bool = false, ?offsets:Array<Point>):Void 
   {
      var perlin = new OptimizedPerlin(randomSeed, numOctaves);
      perlin.fill(this, baseX, baseY, 0);
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
      #if (neko && (!haxe3 || neko_v1))
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

   public function unlock(?changeRect:Rectangle) 
   {
      // Handled internally...
   }

   public function setFormat(format:Int) 
   {
      nme_bitmap_data_set_format(nmeHandle, format);
   }

   public function noise(randomSeed:Int, low:Int = 0, high:Int = 255, channelOptions:Int = 7, grayScale:Bool = false) 
   {
      nme_bitmap_data_noise(nmeHandle, randomSeed, low, high, channelOptions, grayScale);
   }

   // Getters & Setters
   private function get_rect():Rectangle { return new Rectangle(0, 0, width, height); }
   private function get_width():Int { return nme_bitmap_data_width(nmeHandle); }
   private function get_height():Int { return nme_bitmap_data_height(nmeHandle); }
   private function get_transparent():Bool { return nmeTransparent; /*nme_bitmap_data_get_transparent(nmeHandle);*/ }

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
   private static var nme_bitmap_data_flood_fill = Loader.load("nme_bitmap_data_flood_fill", 4);
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

      for(py in 0...height) 
      {
         _x = baseX;

         for(px in 0...width) 
         {
            var s = 0.;

            for(i in 0...octaves) 
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

               var A  =(p[X]) + Y;
               var AA =(p[A]) + Z;
               var AB =(p[A+1]) + Z;
               var B  =(p[X+1]) + Y;
               var BA =(p[B]) + Z;
               var BB =(p[B+1]) + Z;

               var x1 = x-1;
               var y1 = y-1;
               var z1 = z-1;

               var hash =(p[BB+1]) & 15;
               var g1 =((hash&1) == 0 ?(hash<8 ? x1 : y1) :(hash<8 ? -x1 : -y1)) + ((hash&2) == 0 ? hash<4 ? y1 :( hash==12 ? x1 : z1 ) : hash<4 ? -y1 :( hash==14 ? -x1 : -z1 ));

               hash =(p[AB+1]) & 15;
               var g2 =((hash&1) == 0 ?(hash<8 ? x  : y1) :(hash<8 ? -x  : -y1)) + ((hash&2) == 0 ? hash<4 ? y1 :( hash==12 ? x  : z1 ) : hash<4 ? -y1 :( hash==14 ? -x : -z1 ));

               hash =(p[BA+1]) & 15;
               var g3 =((hash&1) == 0 ?(hash<8 ? x1 : y ) :(hash<8 ? -x1 : -y )) + ((hash&2) == 0 ? hash<4 ? y  :( hash==12 ? x1 : z1 ) : hash<4 ? -y  :( hash==14 ? -x1 : -z1 ));

               hash =(p[AA+1]) & 15;
               var g4 =((hash&1) == 0 ?(hash<8 ? x  : y ) :(hash<8 ? -x  : -y )) + ((hash&2) == 0 ? hash<4 ? y  :( hash==12 ? x  : z1 ) : hash<4 ? -y  :( hash==14 ? -x  : -z1 ));

               hash =(p[BB]) & 15;
               var g5 =((hash&1) == 0 ?(hash<8 ? x1 : y1) :(hash<8 ? -x1 : -y1)) + ((hash&2) == 0 ? hash<4 ? y1 :( hash==12 ? x1 : z  ) : hash<4 ? -y1 :( hash==14 ? -x1 : -z  ));

               hash =(p[AB]) & 15;
               var g6 =((hash&1) == 0 ?(hash<8 ? x  : y1) :(hash<8 ? -x  : -y1)) + ((hash&2) == 0 ? hash<4 ? y1 :( hash==12 ? x  : z  ) : hash<4 ? -y1 :( hash==14 ? -x  : -z  ));

               hash =(p[BA]) & 15;
               var g7 =((hash&1) == 0 ?(hash<8 ? x1 : y ) :(hash<8 ? -x1 : -y )) + ((hash&2) == 0 ? hash<4 ? y  :( hash==12 ? x1 : z  ) : hash<4 ? -y  :( hash==14 ? -x1 : -z  ));

               hash =(p[AA]) & 15;
               var g8 =((hash&1) == 0 ?(hash<8 ? x  : y ) :(hash<8 ? -x  : -y )) + ((hash&2) == 0 ? hash<4 ? y  :( hash==12 ? x  : z  ) : hash<4 ? -y  :( hash==14 ? -x  : -z  ));

               g2 += u * (g1 - g2);
               g4 += u * (g3 - g4);
               g6 += u * (g5 - g6);
               g8 += u * (g7 - g8);

               g4 += v * (g2 - g4);
               g8 += v * (g6 - g8);

               s +=( g8 + w * (g4 - g8)) * fPers;
            }

            var color = Std.int(( s * fPersMax + 1 ) * 128);

            #if (neko && (!haxe3 || neko_v1))
            var pixel = { a: 0xFF, rgb: color };
            #else
            var pixel = 0xff000000 | color << 16 | color << 8 | color;
            #end

            bitmap.setPixel32(px, py, pixel);

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

      for(i in 0...octaves) 
      {
         fFreq = Math.pow(2, i);
         fPers = Math.pow(fPersistence, i);
         fPersMax += fPers;
         aOctFreq.push(fFreq);
         aOctPers.push(fPers);
      }

      fPersMax = 1 / fPersMax;
   }

   private function seedOffset(iSeed:Int) 
   {
      #if (neko && (!haxe3 || neko_v1))
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

#end
