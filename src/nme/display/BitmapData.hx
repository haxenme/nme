package nme.display;
#if (!flash)

import haxe.io.Bytes;
import nme.geom.Rectangle;
import nme.geom.Point;
import nme.geom.Matrix;
import nme.geom.ColorTransform;
import nme.filters.BitmapFilter;
import nme.utils.ByteArray;
import nme.PrimeLoader;
import nme.image.PixelFormat;
import nme.NativeHandle;
import nme.utils.UInt8Array;



@:autoBuild(nme.macros.Embed.embedAsset("NME_bitmap_",":bitmap"))
@:nativeProperty
class BitmapData implements IBitmapDrawable 
{
   public inline static var PNG = "png";
   public inline static var JPG = "jpg";

   public static var TRANSPARENT = 0x0001;
   public static var HARDWARE = 0x0002;


   public static var FLAG_NOREPEAT_NONPOT = 0x0001;
   public static var FLAG_FIXED_FORMAT    = 0x0002;
   public static var FLAG_MIPMAPS         = 0x0004;

   public static inline var CHANNEL_RED   = 0x0001;
   public static inline var CHANNEL_GREEN = 0x0002;
   public static inline var CHANNEL_BLUE  = 0x0004;
   public static inline var CHANNEL_ALPHA = 0x0008;

   // float32 transforms
   public static inline var FLOAT_UNSCALED     = 0x0000;
   public static inline var FLOAT_ZERO_MEAN    = 0x0001;
   public static inline var FLOAT_128_MEAN     = 0x0002;
   public static inline var FLOAT_UNIT_SCALE   = 0x0004;
   public static inline var FLOAT_STD_SCALE    = 0x0008;
   public static inline var FLOAT_SWIZZLE_RGB  = 0x0010;
   public static inline var FLOAT_100_SCALE    = 0x0020;
   // zero mean, std scale
   public static inline var FLOAT_NORM       = 0x0009;
   // add 128, * 255
   public static inline var FLOAT_EXPAND     = 0x0006;


   public static var CLEAR = createColor(0, 0);
   public static var BLACK = createColor(0x000000);
   public static var WHITE = createColor(0x000000);
   public static var RED = createColor(0xff0000);
   public static var GREEN = createColor(0x00ff00);
   public static var BLUE = createColor(0x0000ff);

   public static var defaultPremultiplied = true;
   public static var defaultMipmaps = false;

   public var height(get, null):Int;
   public var rect(get, null):Rectangle;
   public var transparent(get, null):Bool;
   public var width(get, null):Int;
   public var format(get, set):Int;
   public var premultipliedAlpha(get, set):Bool;
   public var nmeHandle:NativeHandle;
   public var data(get,null):UInt8Array;
   public var mipmaps(get, set):Bool;
   public static var respectExifOrientation(null, set):Bool;


   public function new(inWidth:Int, inHeight:Int, inTransparent:Bool = true, ?inFillARGB:Int, inPixelFormat:Int = -1)
   {
      nmeHandle = null;

      var pixelFormat:Int = inPixelFormat!=-1      ? inPixelFormat :
                               !inTransparent       ? PixelFormat.pfRGB :
                               defaultPremultiplied ? PixelFormat.pfBGRPremA :
                                                      PixelFormat.pfBGRA;

      if (inWidth>0 && inHeight>0 && pixelFormat!=PixelFormat.pfNone)
      {
         var rgb:Int = inFillARGB==null ? 0 : inFillARGB;

         nmeHandle = nme_bitmap_data_create(inWidth, inHeight, pixelFormat, rgb, (inFillARGB!=null));
      }

      if (nmeHandle==null)
      {
         if (inPixelFormat!=-1 || !inTransparent)
            setFlags( getFlags() | FLAG_FIXED_FORMAT);
         // Check for embedded resource...
         var className = Type.getClass(this);
         if (Reflect.hasField(className, "resourceName"))
         {
            var resoName = Reflect.field(className, "resourceName");
            nmeLoadFromBytes(ByteArray.fromBytes(nme.Assets.getResource(resoName)), null);
         }
      }
      if (nmeHandle!=null && defaultMipmaps)
         mipmaps = true;
   }
   public static function createPremultiplied(width:Int, height:Int, inArgb:Int = 0)
   {
      return new BitmapData(width, height, true, inArgb, PixelFormat.pfBGRPremA);
   }

   public static function createGrey(width:Int, height:Int, ?inLuma:Int)
   {
      return new BitmapData(width, height, false, inLuma, PixelFormat.pfLuma);
   }

   public static function createAlpha(width:Int, height:Int,inAlpha:Int=0)
   {
      return new BitmapData(width, height, false, (inAlpha&0xff)<<24, PixelFormat.pfAlpha);
   }



   public static function createUInt16(width:Int, height:Int) : BitmapData
   {
      return new BitmapData(width, height, false, null, PixelFormat.pfUInt16);
   }


   public static function createUInt32(width:Int, height:Int) : BitmapData
   {
      return new BitmapData(width, height, false, null, PixelFormat.pfUInt32);
   }



   public function clear(color:Int):Void 
   {
      nme_bitmap_data_clear(nmeHandle, color);
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
      var a:Int = inColour >>> 24;
      var c:Int = inColour & 0xffffff;
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

   public function getPixels(?rect:Rectangle):ByteArray 
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


   public function nmeDrawToSurface(inSurface:Dynamic, matrix:Matrix, colorTransform:ColorTransform, blendMode:String, clipRect:Rectangle, smoothing:Bool):Void
   {
      // IBitmapDrawable interface...
      var blendIndex = 0;
      nme_render_surface_to_surface(inSurface, nmeHandle, matrix, colorTransform, blendIndex, clipRect, smoothing);
   }
   
   private inline function nmeLoadFromBytes(inBytes:ByteArray, ?inRawAlpha:ByteArray,
      ?onAppData:(Int, ByteArray)->Void) :Void 
   {
      nmeHandle = nme_bitmap_data_from_bytes(inBytes, inRawAlpha, onAppData);
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

   public function setVector(?rect:Rectangle, inPixels:Array<Int>):Void 
   {
      if (rect==null)
         rect = new Rectangle(0,0,width,height);

      var count = Std.int(rect.width * rect.height);

      if (inPixels.length < count) return;

      #if cpp
      nme_bitmap_data_set_array(nmeHandle, rect, inPixels);
      #else
      var bytes = new ByteArray(0,true);
      for(i in 0...count)
         bytes.writeInt(inPixels[i]);
      nme_bitmap_data_set_bytes(nmeHandle, rect, bytes, 0);
      //bytes.dispose();
      #end
   }

   public function get_data() : UInt8Array
   {
      return UInt8Array.fromBytes( getPixels() );
   }

   // Get the pixels and fill  a (region) of a byte buffer of given pixel format.
   // The buffer should be allocated with enough room to hold the data
   // Pixel conversion between non-float types will take place (eg, pfLuma -> pfRGB)
   // dataHandle may be:
   //   * A handle from an external function generating "data" abstract data,
   //        or from a cpp.Pointer
   //   * nme.utils.ByteArray or haxe byte Array
   //   * Array<Int>

   public function getData(dataHandle:Dynamic, inPixelFormat=-1, dataOffset=0, dataStride=0, subSample = 1)
   {
      var pf:Int = inPixelFormat==-1 ? format : inPixelFormat;
      nme_bitmap_data_get_uints8(nmeHandle,dataHandle, dataOffset, dataStride, pf, subSample);
   }

   // Get raw pointer to image data - you can use Pointer.fromHandle(...);
   public function getDataHandle() : Dynamic
   {
      return nme_bitmap_data_get_data_handle(nmeHandle);
   }




   public function getBytes(inPixelFormat:Int=-1) : ByteArray
   {
      var pf:Int = inPixelFormat==-1 ? format : inPixelFormat;
      var size = width * height * PixelFormat.getPixelSize(pf);
      var result = new ByteArray(size);
      getData(result,pf);
      return result;
   }

   // use getData instead
   inline public function getUInts8(dataHandle:Dynamic, dataOffset:Int, dataStride:Int,
           pixelFormat:Int, subSample:Int = 1)
        getData(dataHandle, pixelFormat, dataOffset, dataStride, subSample);

   // Set the pixels from a (region) of a byte buffer of given pixel format.
   // Pixel conversion between non-float types will take place (eg, pfLuma -> pfRGB)
   // dataHandle may be:
   //   * A handle from an external function generating "data" abstract data,
   //   * From a cpp.Pointer (eg: setData(Pointer.ofArray(array)) )
   //   * nme.utils.ByteArray or haxe ByteArray
   //   * Array<Int>
   public function setData(dataHandle:Dynamic, inPixelFormat=-1, dataOffset=0, dataStride=0, expand=1)
   {
      var pf:Int = inPixelFormat==-1 ? format : inPixelFormat;
      nme_bitmap_data_set_uints8(nmeHandle,dataHandle, dataOffset, dataStride, pf, expand);
   }
 
   // use setData instead
   inline public function setUInts8(dataHandle:Dynamic, dataOffset:Int, dataStride:Int, pixelFormat:Int, expand=1)
       setData(dataHandle, pixelFormat, dataOffset, dataStride, expand);



   public function getFloats32(dataHandle:Dynamic, dataOffset:Int, dataStride:Int,
           pixelFormat:Int, transform:Int, subSample:Int = 1, ?subrect:Rectangle)
   {
      nme_bitmap_data_get_floats32(nmeHandle,dataHandle, dataOffset, dataStride, pixelFormat, transform, subSample, subrect);
   }


   public function setFloats32(dataHandle:Dynamic, dataOffset:Int, dataStride:Int,
           pixelFormat:Int, transform:Int, expand:Int = 1, ?subrect:Rectangle)
   {
      nme_bitmap_data_set_floats32(nmeHandle,dataHandle, dataOffset, dataStride, pixelFormat, transform, expand,subrect);
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
   private function get_mipmaps():Bool
   {
      return (getFlags() & FLAG_MIPMAPS) > 0;
   }
   private function set_mipmaps(inMipmaps:Bool):Bool
   {
      var f = getFlags();
      if ( ((f & FLAG_MIPMAPS)!=0) !=  inMipmaps)
      {
         if (inMipmaps)
            setFlags(f | FLAG_MIPMAPS);
         else
            setFlags(f & ~FLAG_MIPMAPS);
      }

      return inMipmaps;
   }

   public function applyFilter(sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point, filter:BitmapFilter):Void 
   {
      nme_bitmap_data_apply_filter(nmeHandle, sourceBitmapData.nmeHandle, sourceRect, destPoint, filter);
   }

   public function clone():BitmapData 
   {
      var bm = new BitmapData(0, 0, false,0,PixelFormat.pfNone);
      bm.nmeHandle = nme_bitmap_data_clone(nmeHandle);
      bm.mipmaps = mipmaps;
      return bm;
   }

   public function cloneRect(x0:Int, y0:Int, inWidth:Int, inHeight:Int):BitmapData 
   {
      var result = new BitmapData(inWidth,inHeight,transparent,0,format);

      result.copyPixels(this, new Rectangle(x0,y0,inWidth,inHeight), new Point(0,0), null, null, false );
      result.mipmaps = mipmaps;

      return result;
   }

   public static inline function createColor(inRGB:Int, inAlpha:Int = 0xFF):Int 
   {
      return inRGB |(inAlpha << 24);
   }

   public function draw(source:IBitmapDrawable, matrix:Matrix = null, colorTransform:ColorTransform = null, blendMode:BlendMode = null, clipRect:Rectangle = null, smoothing:Bool = false):Void 
   {
      source.nmeDrawToSurface(nmeHandle, matrix, colorTransform, Std.string(blendMode), clipRect, smoothing);
   }

   // BitmapData are currently stored unmultiplied on nme
   public inline function unmultiplyAlpha() { }

   public static inline function extractAlpha(v:Int):Int { return v >>> 24; }

   public static inline function extractColor(v:Int):Int { return v & 0xFFFFFF; }

   static function set_respectExifOrientation(val:Bool)
   {
      nme_bitmap_data_set_respect_exif_orientation(val);
      return val;
   }

   static inline function sameValue(a:Int, b:Int)
   {
      return a==b;
   }
   
   /**
    * Flips an ARGB pixel value to BGRA or vice-versa
    * @param   pix4 a 4-byte pixel value in AARRGGBB or BBGGRRAA format
    * @return   pix4 flipped-endian format
    */
   
   public static inline function flip_pixel4(pix4:Int):Int{
      return (pix4       & 0xFF) << 24 |   //4th byte --> 1st byte
           (pix4 >>  8 & 0xFF) << 16 |   //3rd byte --> 2nd byte
           (pix4 >> 16 & 0xFF) <<  8 |   //2nd byte --> 3rd byte
           (pix4 >> 24 & 0xFF);          //1st byte --> 4th byte
   }
   
   /**
    * Tests pixel values in an image against a specified threshold and sets pixels that pass the test to new color values.
    * @param   sourceBitmapData input bitmap data. Source can be different BitmapData or can refer to current BitmapData. 
    * @param   sourceRect rectangle that defines area of source image to use as input. 
    * @param   destPoint point within destination image (current BitmapData) corresponding to upper-left corner of source rectangle. 
    * @param   operation one of these strings: "<", "<=", ">", ">=", "==", "!="
    * @param   threshold value each pixel is tested against to see if it meets or exceeds the threshhold.
    * @param   color color value a pixel is set to if threshold test succeeds.
    * @param   mask mask used to isolate a color component. 
    * @param   copySource If true, pixel values from source image are copied to destination when threshold test fails. If false, source image is not copied when threshold test fails.
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
      var bd1 = sourceBitmapData.clone();
      mem.writeBytes(bd1.getPixels(sourceRect));
      mem.position = canvas_mem;
      if(copySource){
         var bd2 = sourceBitmapData.clone();
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
   bd1.setPixels(sourceRect, mem);         //draw to our temp buffer
   copyPixels(bd1, bd1.rect, destPoint);   //draw to this bitmapdata at offset point
   Memory.select(null);
   return hits;   //# of pixels changed
   }
   
   //******Replaces Int32.ucompare()******//
   
   /**
    * Compare 2 integers, byte-for-byte (unsigned mode)
    * @param   n1   an integer
    * @param   n2   another integer
    * @return   0 if n1 == n2, 1 if n1 > n2, -1 if n1 < n2
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
    * @param   operation
    * @param   threshold
    * @param   color
    * @param   mask
    * @param   copySource
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

   public static function getRGBAPixels(bitmapData:BitmapData):ByteArray 
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

   public static function load(inFilename:String, format:Int = -1, ?inOnMarker:(Int,ByteArray)->Void):BitmapData 
   {
      var result = new BitmapData(0, 0);
      result.nmeHandle = nme_bitmap_data_load(inFilename, format, inOnMarker);
      if (result.width<1 || result.height<1)
         return null;
      if (result.nmeHandle!=null && defaultMipmaps)
         result.mipmaps = true;
      return result;
   }


   #if !no_nme_io
   public function save(inFilename:String, inQuality:Float = 0.9):Void
   {
      var ext = inFilename.length>3 ? inFilename.substr(inFilename.length-3).toLowerCase() : PNG;
      if (ext=="jpg" || ext=="peg")
         ext = JPG;
      else
         ext = PNG;
      var bytes = encode(ext, inQuality);
      bytes.writeFile(inFilename);
   }
   #end

   public static function loadFromBytes(inBytes:ByteArray, ?inRawAlpha:ByteArray, ?inOnMarker:(Int,ByteArray)->Void):BitmapData 
   {
      var result = new BitmapData(0, 0);
      result.nmeLoadFromBytes(inBytes, inRawAlpha, inOnMarker);
      if (result.width<1 || result.height<1)
         return null;
      if (result.nmeHandle!=null && defaultMipmaps)
         result.mipmaps = true;
      return result;
   }

   public static function loadFromHaxeBytes(inBytes:Bytes, ?inRawAlpha:Bytes,?inOnMarker:(Int,ByteArray)->Void)  : BitmapData
   {
      return loadFromBytes(ByteArray.fromBytes(inBytes), inRawAlpha == null ? null : ByteArray.fromBytes(inRawAlpha), inOnMarker);
   }

   public function lock() 
   {
      // Handled internally...
   }

   public function unlock(?changeRect:Rectangle) 
   {
      // Handled internally...
   }



   public function downscaleFit(w:Int, h:Int, bgCol = 0)
   {
      var src = this;

      while(src.width>=w*2 || src.height>h*2)
      {
         var dest = new BitmapData(src.width>>1, src.height>>1, false, bgCol);
         var mtx = new Matrix();
         mtx.a = dest.width/src.width;
         mtx.d = dest.height/src.height;
         mtx.tx = 0;
         mtx.ty = 0;
         dest.draw(src,mtx,true);
         src = dest;
      }
      var dest = new BitmapData(w, h, false, bgCol);

      var scale = Math.min(  dest.width/src.width, dest.height/src.height );

      var mtx = new Matrix();
      mtx.a = scale;
      mtx.d = scale;
      mtx.tx = (w - scale*src.width) / 2;
      mtx.ty = (h - scale*src.height) / 2;
      dest.draw(src,mtx,true);

      return dest;
   }


   public function toString():String
   {
      return 'BitmapData($width,$height)';
   }

   // Native Methods
   private static var nme_bitmap_data_apply_filter = PrimeLoader.load("nme_bitmap_data_apply_filter", "ooooov");
   private static var nme_bitmap_data_generate_filter_rect = PrimeLoader.load("nme_bitmap_data_generate_filter_rect", "ooov");
   private static var nme_bitmap_data_create = PrimeLoader.load("nme_bitmap_data_create", "iiiibo");
   private static var nme_bitmap_data_load = PrimeLoader.load("nme_bitmap_data_load", "oooo");
   private static var nme_bitmap_data_from_bytes = PrimeLoader.load("nme_bitmap_data_from_bytes", "oooo");
   private static var nme_bitmap_data_clear = PrimeLoader.load("nme_bitmap_data_clear", "oiv");
   private static var nme_bitmap_data_clone = PrimeLoader.load("nme_bitmap_data_clone", "oo");
   //private static var nme_bitmap_data_apply_filter = nme.Loader.load("nme_bitmap_data_apply_filter", 5);
   private static var nme_bitmap_data_color_transform = PrimeLoader.load("nme_bitmap_data_color_transform", "ooov");
   private static var nme_bitmap_data_copy = PrimeLoader.load("nme_bitmap_data_copy", "oooobv");
   private static var nme_bitmap_data_copy_channel = PrimeLoader.load("nme_bitmap_data_copy_channel", "ooooiiv");
   private static var nme_bitmap_data_fill = PrimeLoader.load("nme_bitmap_data_fill", "ooiiv");
   private static var nme_bitmap_data_get_pixels = PrimeLoader.load("nme_bitmap_data_get_pixels", "ooo");
   private static var nme_bitmap_data_get_pixel = PrimeLoader.load("nme_bitmap_data_get_pixel", "oiii");
   private static var nme_bitmap_data_get_pixel32 = PrimeLoader.load("nme_bitmap_data_get_pixel32", "oiii");
   #if cpp
   private static var nme_bitmap_data_get_array = PrimeLoader.load("nme_bitmap_data_get_array", "ooov");
   #end
   private static var nme_bitmap_data_get_color_bounds_rect = PrimeLoader.load("nme_bitmap_data_get_color_bounds_rect", "oiibov");
   private static var nme_bitmap_data_scroll = PrimeLoader.load("nme_bitmap_data_scroll", "oiiv");
   private static var nme_bitmap_data_set_pixel = PrimeLoader.load("nme_bitmap_data_set_pixel", "oiiiv");
   private static var nme_bitmap_data_set_pixel32 = PrimeLoader.load("nme_bitmap_data_set_pixel32", "oiiiv");
//   private static var nme_bitmap_data_set_pixel_rgba = nme.Loader.load("nme_bitmap_data_set_pixel_rgba", 4);
   private static var nme_bitmap_data_set_bytes = PrimeLoader.load("nme_bitmap_data_set_bytes", "oooiv");
   private static var nme_bitmap_data_set_format = PrimeLoader.load("nme_bitmap_data_set_format", "oibv");
   private static var nme_bitmap_data_get_format = PrimeLoader.load("nme_bitmap_data_get_format", "oi");
   #if cpp
   private static var nme_bitmap_data_set_array = PrimeLoader.load("nme_bitmap_data_set_array", "ooov");
   #end
   private static var nme_bitmap_data_create_hardware_surface = PrimeLoader.load("nme_bitmap_data_create_hardware_surface", "ov");
   private static var nme_bitmap_data_destroy_hardware_surface = PrimeLoader.load("nme_bitmap_data_destroy_hardware_surface", "ov");
//   private static var nme_bitmap_data_generate_filter_rect = PrimeLoader.load("nme_bitmap_data_generate_filter_rect", 3);
   private static var nme_render_surface_to_surface = PrimeLoader.load("nme_render_surface_to_surface", "ooooiobv");
   private static var nme_bitmap_data_height = PrimeLoader.load("nme_bitmap_data_height", "oi");
   private static var nme_bitmap_data_width = PrimeLoader.load("nme_bitmap_data_width", "oi");
   private static var nme_bitmap_data_get_transparent = PrimeLoader.load("nme_bitmap_data_get_transparent", "ob");
   private static var nme_bitmap_data_set_flags = PrimeLoader.load("nme_bitmap_data_set_flags", "oiv");
   private static var nme_bitmap_data_get_flags = PrimeLoader.load("nme_bitmap_data_get_flags", "oi");
   private static var nme_bitmap_data_encode = nme.Loader.load("nme_bitmap_data_encode", 3);
   private static var nme_bitmap_data_dump_bits = PrimeLoader.load("nme_bitmap_data_dump_bits", "ov");
   private static var nme_bitmap_data_dispose = PrimeLoader.load("nme_bitmap_data_dispose", "ov");
   private static var nme_bitmap_data_noise = PrimeLoader.load("nme_bitmap_data_noise", "oiiiibv");
   private static var nme_bitmap_data_flood_fill = PrimeLoader.load("nme_bitmap_data_flood_fill", "oiiiv");
   private static var nme_bitmap_data_get_prem_alpha = PrimeLoader.load("nme_bitmap_data_get_prem_alpha", "ob");
   private static var nme_bitmap_data_set_prem_alpha = PrimeLoader.load("nme_bitmap_data_set_prem_alpha", "obv");
   private static var nme_bitmap_data_get_floats32 = PrimeLoader.load("nme_bitmap_data_get_floats32", "ooiiiiiov");
   private static var nme_bitmap_data_set_floats32 = PrimeLoader.load("nme_bitmap_data_set_floats32", "ooiiiiiov");
   private static var nme_bitmap_data_get_uints8 = PrimeLoader.load("nme_bitmap_data_get_uints8", "ooiiiiv");
   private static var nme_bitmap_data_set_uints8 = PrimeLoader.load("nme_bitmap_data_set_uints8", "ooiiiiv");
   private static var nme_bitmap_data_get_data_handle = PrimeLoader.load("nme_bitmap_data_get_data_handle", "oo");
   private static var nme_bitmap_data_set_respect_exif_orientation = PrimeLoader.load("nme_bitmap_data_set_respect_exif_orientation", "bv");
}


#else
typedef BitmapData = flash.display.BitmapData;
#end
