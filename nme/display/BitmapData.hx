package nme.display;
#if (!flash)

import haxe.io.Bytes;
import nme.bare.Surface;
import nme.geom.Rectangle;
import nme.geom.Point;
import nme.geom.Matrix;
import nme.geom.ColorTransform;
import nme.filters.BitmapFilter;
import nme.utils.ByteArray;
import nme.Loader;


@:autoBuild(nme.macros.Embed.embedAsset("NME_bitmap_",":bitmap"))
@:nativeProperty
class BitmapData extends Surface implements IBitmapDrawable 
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
   public static var FORMAT_LUMA:Int = 3;  //8 bit, luma
   public static var FORMAT_LUMA_ALPHA:Int = 4;  //16 bit, luma + alpha
   public static var FORMAT_RGB:Int = 5;  //24 bit, rgb
   public static var FORMAT_YUVSP:Int = 6;  // Plane of Y followed by interleaved UV
   public static var FORMAT_BGRPremA:Int = 7;  // Plane of Y followed by interleaved UV
   public static var FORMAT_UINT16:Int = 8;  // 16-bit channel
   public static var FORMAT_UINT32:Int = 9;  // 32-bit channel

   public function new(inWidth:Int, inHeight:Int, inTransparent:Bool = true, ?inFillARGB:Int, ?inInternalFormat:Null<Int>)
   {
      super(inWidth, inHeight, inTransparent, inFillARGB, inInternalFormat );

      if (nmeHandle==null)
      {
         // Check for embedded resource...
         var className = Type.getClass(this);
         if (Reflect.hasField(className, "resourceName"))
         {
            var resoName = Reflect.field(className, "resourceName");
            nmeLoadFromBytes(ByteArray.fromBytes(haxe.Resource.getBytes(resoName)), null);
         }
      }
   }
   public static function createPremultiplied(width:Int, height:Int, inRgba:Int = 0)
   {
      return new BitmapData(width, height, true, inRgba, FORMAT_BGRPremA);
   }

   public static function createGrey(width:Int, height:Int, ?inLuma:Int)
   {
      return new BitmapData(width, height, false, inLuma, FORMAT_LUMA);
   }

   public function applyFilter(sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point, filter:BitmapFilter):Void 
   {
      nme_bitmap_data_apply_filter(nmeHandle, sourceBitmapData.nmeHandle, sourceRect, destPoint, filter);
   }

   override public function clone():BitmapData 
   {
      var bm = new BitmapData(0, 0, transparent);
      bm.nmeHandle = Surface.nme_bitmap_data_clone(nmeHandle);
      return bm;
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


   static inline function sameValue(a:Int, b:Int)
   {
      return a==b;
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
		var bd1:Surface = sourceBitmapData.clone();
		mem.writeBytes(bd1.getPixels(sourceRect));
		mem.position = canvas_mem;
		if(copySource){
			var bd2:Surface = sourceBitmapData.clone();
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

   public static function load(inFilename:String, format:Int = 0):BitmapData 
   {
      var result = new BitmapData(0, 0);
      result.nmeHandle = Surface.nme_bitmap_data_load(inFilename, format);
      return result;
   }

   public static function loadFromBytes(inBytes:ByteArray, ?inRawAlpha:ByteArray):BitmapData 
   {
      var result = new BitmapData(0, 0);
      result.nmeLoadFromBytes(inBytes, inRawAlpha);
      return result;
   }

   public static function loadFromHaxeBytes(inBytes:Bytes, ?inRawAlpha:Bytes)  : BitmapData
   {
      return loadFromBytes(ByteArray.fromBytes(inBytes), inRawAlpha == null ? null : ByteArray.fromBytes(inRawAlpha));
   }

   public function lock() 
   {
      // Handled internally...
   }

   public function unlock(?changeRect:Rectangle) 
   {
      // Handled internally...
   }

   // Native Methods
   private static var nme_bitmap_data_apply_filter = Loader.load("nme_bitmap_data_apply_filter", 5);
   private static var nme_bitmap_data_generate_filter_rect = Loader.load("nme_bitmap_data_generate_filter_rect", 3);
}


#else
typedef BitmapData = flash.display.BitmapData;
#end
