package nme.display;


#if flash
@:native ("flash.display.BitmapData")
extern class BitmapData implements IBitmapDrawable {
	var height(default,null) : Int;
	var rect(default,null) : nme.geom.Rectangle;
	var transparent(default,null) : Bool;
	var width(default,null) : Int;
	function new(width : Int, height : Int, transparent : Bool = true, fillColor : UInt = 0xFFFFFFFF) : Void;
	function applyFilter(sourceBitmapData : BitmapData, sourceRect : nme.geom.Rectangle, destPoint : nme.geom.Point, filter : nme.filters.BitmapFilter) : Void;
	function clone() : BitmapData;
	function colorTransform(rect : nme.geom.Rectangle, colorTransform : nme.geom.ColorTransform) : Void;
	function compare(otherBitmapData : BitmapData) : Dynamic;
	function copyChannel(sourceBitmapData : BitmapData, sourceRect : nme.geom.Rectangle, destPoint : nme.geom.Point, sourceChannel : UInt, destChannel : UInt) : Void;
	function copyPixels(sourceBitmapData : BitmapData, sourceRect : nme.geom.Rectangle, destPoint : nme.geom.Point, ?alphaBitmapData : BitmapData, ?alphaPoint : nme.geom.Point, mergeAlpha : Bool = false) : Void;
	function dispose() : Void;
	function draw(source : IBitmapDrawable, ?matrix : nme.geom.Matrix, ?colorTransform : nme.geom.ColorTransform, ?blendMode : BlendMode, ?clipRect : nme.geom.Rectangle, smoothing : Bool = false) : Void;
	function fillRect(rect : nme.geom.Rectangle, color : UInt) : Void;
	function floodFill(x : Int, y : Int, color : UInt) : Void;
	function generateFilterRect(sourceRect : nme.geom.Rectangle, filter : nme.filters.BitmapFilter) : nme.geom.Rectangle;
	function getColorBoundsRect(mask : UInt, color : UInt, findColor : Bool = true) : nme.geom.Rectangle;
	function getPixel(x : Int, y : Int) : UInt;
	function getPixel32(x : Int, y : Int) : UInt;
	function getPixels(rect : nme.geom.Rectangle) : nme.utils.ByteArray;
	@:require(flash10) function getVector(rect : nme.geom.Rectangle) : nme.Vector<UInt>;
	@:require(flash10) function histogram(?hRect : nme.geom.Rectangle) : nme.Vector<nme.Vector<Float>>;
	function hitTest(firstPoint : nme.geom.Point, firstAlphaThreshold : UInt, secondObject : Dynamic, ?secondBitmapDataPoint : nme.geom.Point, secondAlphaThreshold : UInt = 1) : Bool;
	function lock() : Void;
	function merge(sourceBitmapData : BitmapData, sourceRect : nme.geom.Rectangle, destPoint : nme.geom.Point, redMultiplier : UInt, greenMultiplier : UInt, blueMultiplier : UInt, alphaMultiplier : UInt) : Void;
	function noise(randomSeed : Int, low : UInt = 0, high : UInt = 255, channelOptions : UInt = 7, grayScale : Bool = false) : Void;
	function paletteMap(sourceBitmapData : BitmapData, sourceRect : nme.geom.Rectangle, destPoint : nme.geom.Point, ?redArray : Array<Int>, ?greenArray : Array<Int>, ?blueArray : Array<Int>, ?alphaArray : Array<Int>) : Void;
	function perlinNoise(baseX : Float, baseY : Float, numOctaves : UInt, randomSeed : Int, stitch : Bool, fractalNoise : Bool, channelOptions : UInt = 7, grayScale : Bool = false, ?offsets : Array<nme.geom.Point>) : Void;
	function pixelDissolve(sourceBitmapData : BitmapData, sourceRect : nme.geom.Rectangle, destPoint : nme.geom.Point, randomSeed : Int = 0, numPixels : Int = 0, fillColor : UInt = 0) : Int;
	function scroll(x : Int, y : Int) : Void;
	function setPixel(x : Int, y : Int, color : UInt) : Void;
	function setPixel32(x : Int, y : Int, color : UInt) : Void;
	function setPixels(rect : nme.geom.Rectangle, inputByteArray : nme.utils.ByteArray) : Void;
	@:require(flash10) function setVector(rect : nme.geom.Rectangle, inputVector : nme.Vector<UInt>) : Void;
	function threshold(sourceBitmapData : BitmapData, sourceRect : nme.geom.Rectangle, destPoint : nme.geom.Point, operation : String, threshold : UInt, color : UInt = 0, mask : UInt = 0xFFFFFFFF, copySource : Bool = false) : UInt;
	function unlock(?changeRect : nme.geom.Rectangle) : Void;
}
#else



import haxe.io.Bytes;
import nme.geom.Rectangle;
import nme.geom.Point;
import nme.geom.Matrix;
import nme.geom.ColorTransform;
import nme.utils.ByteArray;


/**
* @author   Hugh Sanderson
* @author   Russell Weir
* @todo getPixel, getPixel32 should be optimized to use library methods
*/
class BitmapData implements IBitmapDrawable
{
   public var width(nmeGetWidth,null):Int;
   public var height(nmeGetHeight,null):Int;
   public var rect(nmeGetRect,null) : nme.geom.Rectangle;
   public var transparent(nmeGetTransparent,null) : Bool;

   public static var TRANSPARENT = 0x0001;
   public static var HARDWARE    = 0x0002;

   public inline static var CLEAR = createColor(0,0);
   public inline static var BLACK = createColor(0x000000);
   public inline static var WHITE =  createColor(0x000000);
   public inline static var RED =  createColor(0xff0000);
   public inline static var GREEN =  createColor(0x00ff00);
   public inline static var BLUE =  createColor(0x0000ff);

   // Public, but only use if you know what you are doing
   public var nmeHandle:Dynamic;

   public inline static var PNG = "png";
   public inline static var JPG = "jpg";


   public function new(inWidth:Int, inHeight:Int,
                  inTransparent:Bool=true,
                  ?inFillRGBA:BitmapInt32 )
   {
      var fill_col:Int;
      var fill_alpha:Int;

      if (inFillRGBA==null)
      {
         fill_col = 0xffffff;
         fill_alpha = 0xff;
      }
      else
      {
         fill_col = extractColor(inFillRGBA);
         fill_alpha = extractAlpha(inFillRGBA);
      }

      if (inWidth<1 || inHeight<1) {
         nmeHandle = null;
      }
      else
      {
         var flags = HARDWARE;
         if (inTransparent)
            flags |= TRANSPARENT;
         nmeHandle = nme_bitmap_data_create(inWidth,inHeight,flags,fill_col,fill_alpha);
      }
   }

   /**
   * Load from a file path
   *
   * @param inFilename Full or relative path to image file
   * @return New BitmapData instance representing file
   **/
   static public function load(inFilename:String) : BitmapData
   {
      var result = new BitmapData(0,0);
      result.nmeHandle = nme_bitmap_data_load(inFilename);
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
   static public function loadFromBytes(inBytes:nme.utils.ByteArray, ?inRawAlpha:nme.utils.ByteArray)
   {
      var result = new BitmapData(0,0);
      result.nmeHandle = nme_bitmap_data_from_bytes( inBytes,inRawAlpha );
      return result;
   }

   // Same as above, except uses haxe.ioBytes
   static public function loadFromHaxeBytes(inBytes:haxe.io.Bytes, ?inRawAlpha:haxe.io.Bytes)
   {
      return loadFromBytes( ByteArray.fromBytes(inBytes),
                                inRawAlpha==null ? ByteArray.fromBytes(inRawAlpha) : null);
   }

   public function encode(inFormat:String, inQuality:Float=0.9 ) : nme.utils.ByteArray
   {
      return nme_bitmap_data_encode(nmeHandle, inFormat, inQuality);
   }


   // --- Flash like API ----------------------------------------------------

   public function clear( color : Int ) : Void
   {
      nme_bitmap_data_clear( nmeHandle, color );
   }

   public function clone() : BitmapData {
      var bm = new BitmapData(0, 0);
      bm.nmeHandle = nme_bitmap_data_clone(nmeHandle);
      return bm;
   }

   public function copyPixels(sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point,
      ?alphaBitmapData:BitmapData, ?alphaPoint:Point, mergeAlpha:Bool = false):Void
   {
      nme_bitmap_data_copy(sourceBitmapData.nmeHandle, sourceRect, nmeHandle, destPoint, mergeAlpha );
   }

   public function copyChannel(sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point,
      inSourceChannel:Int, inDestChannel:Int ):Void
   {
      nme_bitmap_data_copy_channel(sourceBitmapData.nmeHandle, sourceRect, nmeHandle, destPoint,
        inSourceChannel, inDestChannel);
   }


   public function applyFilter(sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point, filter:nme.filters.BitmapFilter):Void
   {
      nme_bitmap_data_apply_filter(nmeHandle, sourceBitmapData.nmeHandle, sourceRect, destPoint, filter);
   }

   public function colorTransform(rect:Rectangle, colorTransform:ColorTransform):Void
   {
      nme_bitmap_data_color_transform(nmeHandle, rect, colorTransform );
   }



   public function dispose()
   {
      nmeHandle = null;
   }

   public function draw(source:IBitmapDrawable,
               matrix:Matrix = null,
               colorTransform:ColorTransform = null,
               blendMode:String = null,
               clipRect:Rectangle = null,
               smoothing:Bool= false):Void
   {
      source.nmeDrawToSurface(nmeHandle,matrix,colorTransform,blendMode,clipRect,smoothing);
   }


   public function fillRect( rect : nme.geom.Rectangle, inColour : BitmapInt32 ) : Void
   {
      var a = extractAlpha(inColour);
      var c = extractColor(inColour);
      nme_bitmap_data_fill(nmeHandle, rect, c, a);
   }

   public function fillRectEx( rect : nme.geom.Rectangle, inColour : Int, inAlpha:Int = 255 ) : Void
   {
      nme_bitmap_data_fill(nmeHandle,rect,inColour,inAlpha);
   }


   public function getColorBoundsRect(mask:BitmapInt32, color: BitmapInt32, findColor:Bool = true):Rectangle
   {
      var result = new Rectangle();
      nme_bitmap_data_get_color_bounds_rect(nmeHandle,mask,color,findColor,result);
      return result;
      
   }

   public function getPixels(rect:Rectangle):ByteArray
   {
      var result:ByteArray = nme_bitmap_data_get_pixels(nmeHandle,rect);
      if (result!=null)
         result.position = result.length;
      return result;
   }

   public function getVector(rect:Rectangle):Array<Int>
   {
      var pixels = Std.int(rect.width * rect.height);
      if (pixels<1)
         return [];
      var result = new Array<Int>();
      result[pixels-1] = 0;

      #if cpp
      nme_bitmap_data_get_array(nmeHandle,rect,result);
      #else
      var bytes:ByteArray = nme_bitmap_data_get_pixels(nmeHandle,rect);
      bytes.position = 0;
      for(i in 0...pixels)
         result[i] = bytes.readInt();
      #end

      return result;
   }



   public function getPixel(x:Int, y:Int) : Int
   {
      return nme_bitmap_data_get_pixel(nmeHandle, x, y);
   }

   public function getPixel32(x:Int, y:Int) : BitmapInt32
   {
   #if neko
      return nme_bitmap_data_get_pixel_rgba(nmeHandle, x, y);
   #else
      return nme_bitmap_data_get_pixel32(nmeHandle, x, y);
   #end
   }


   // Handled internally...
   public function lock() { }

   public function scroll(inDX:Int, inDY:Int)
   {
      nme_bitmap_data_scroll(nmeHandle,inDX,inDY);
   }

   public function setPixel32(inX:Int, inY:Int, inColour: BitmapInt32) : Void
   {
   #if neko
      nme_bitmap_data_set_pixel_rgba(nmeHandle, inX, inY, inColour);
   #else
      nme_bitmap_data_set_pixel32(nmeHandle, inX, inY, inColour);
   #end
   }
   public function setPixel(inX:Int, inY:Int, inColour: Int) : Void
   {
      nme_bitmap_data_set_pixel(nmeHandle, inX, inY, inColour);
   }

   public function generateFilterRect(sourceRect:Rectangle, filter:nme.filters.BitmapFilter):Rectangle
   {
      var result = new Rectangle();
      nme_bitmap_data_generate_filter_rect(sourceRect,filter,result);
      return result;
   }


   public function setPixels(rect:Rectangle,pixels:ByteArray) : Void
   {
      var size = Std.int(rect.width*rect.height*4);
      pixels.checkData(Std.int(size) );
      nme_bitmap_data_set_bytes(nmeHandle,rect,pixels,pixels.position);
      pixels.position+=size;
   }


   public function setVector(rect:Rectangle,inPixels:Array<Int>) : Void
   {
      var count = Std.int(rect.width * rect.height);
      if (inPixels.length<count)
         return;

      #if cpp
      nme_bitmap_data_set_array(nmeHandle,rect,inPixels);
      #else
      var bytes:ByteArray = new ByteArray();
      for(i in 0...count)
         bytes.writeInt(inPixels[i]);
      nme_bitmap_data_set_bytes(nmeHandle,rect,bytes,0);
      #end
   }


   // Handled internally...
   public function unlock(?changeRect:nme.geom.Rectangle) { }


   // IBitmapDrawable interface...
   public function nmeDrawToSurface(inSurface : Dynamic,
               matrix:nme.geom.Matrix,
               colorTransform:nme.geom.ColorTransform,
               blendMode:String,
               clipRect:nme.geom.Rectangle,
               smoothing:Bool):Void
   {
      nme_render_surface_to_surface(inSurface, nmeHandle,
         matrix, colorTransform, blendMode, clipRect, smoothing );
   }


   // Used for optimization
   public function setFlags(inFlags:Int) : Void
   {
      nme_bitmap_data_set_flags(nmeHandle,inFlags);
   }



   // --- Properties -------------------------------------------------

   function nmeGetRect() : Rectangle { return new Rectangle(0,0,width,height); }
   function nmeGetWidth() : Int { return nme_bitmap_data_width(nmeHandle); }
   function nmeGetHeight()  : Int { return nme_bitmap_data_height(nmeHandle); }
   function nmeGetTransparent() : Bool { return nme_bitmap_data_get_transparent(nmeHandle); }


   // --- Statics --------------------------------------------------

   public static inline function extractAlpha(v : BitmapInt32) : Int {
      return
         #if neko
            return v.a;
         #else
            v >>> 24;
         #end
   }

   public static inline function extractColor(v : BitmapInt32) : Int {
      return
         #if neko
            return v.rgb;
         #else
            v & 0xFFFFFF;
         #end
   }

   public static inline function createColor(inRGB:Int,inAlpha:Int=0xff) : BitmapInt32 {
      return
         #if neko
            return { rgb:inRGB, a:inAlpha };
         #else
            inRGB | (inAlpha<<24);
         #end
   }


   static var nme_bitmap_data_create = nme.Loader.load("nme_bitmap_data_create",5);
   static var nme_bitmap_data_load = nme.Loader.load("nme_bitmap_data_load",1);
   static var nme_bitmap_data_from_bytes = nme.Loader.load("nme_bitmap_data_from_bytes",2);
   static var nme_bitmap_data_clear = nme.Loader.load("nme_bitmap_data_clear",2);
   static var nme_bitmap_data_clone = nme.Loader.load("nme_bitmap_data_clone",1);
   static var nme_bitmap_data_apply_filter = nme.Loader.load("nme_bitmap_data_apply_filter",5);
   static var nme_bitmap_data_color_transform = nme.Loader.load("nme_bitmap_data_color_transform",3);
   static var nme_bitmap_data_copy = nme.Loader.load("nme_bitmap_data_copy",5);
   static var nme_bitmap_data_copy_channel = nme.Loader.load("nme_bitmap_data_copy_channel", -1);
   static var nme_bitmap_data_fill = nme.Loader.load("nme_bitmap_data_fill",4);
   static var nme_bitmap_data_get_pixels = nme.Loader.load("nme_bitmap_data_get_pixels",2);
   static var nme_bitmap_data_get_pixel = nme.Loader.load("nme_bitmap_data_get_pixel",3);
   static var nme_bitmap_data_get_pixel32 = nme.Loader.load("nme_bitmap_data_get_pixel32",3);
   static var nme_bitmap_data_get_pixel_rgba = nme.Loader.load("nme_bitmap_data_get_pixel_rgba",3);
   #if cpp
   static var nme_bitmap_data_get_array = nme.Loader.load("nme_bitmap_data_get_array",3);
   #end
   static var nme_bitmap_data_get_color_bounds_rect = nme.Loader.load("nme_bitmap_data_get_color_bounds_rect",5);
   static var nme_bitmap_data_scroll = nme.Loader.load("nme_bitmap_data_scroll",3);
   static var nme_bitmap_data_set_pixel = nme.Loader.load("nme_bitmap_data_set_pixel",4);
   static var nme_bitmap_data_set_pixel32 = nme.Loader.load("nme_bitmap_data_set_pixel32",4);
   static var nme_bitmap_data_set_pixel_rgba = nme.Loader.load("nme_bitmap_data_set_pixel_rgba",4);
   static var nme_bitmap_data_set_bytes = nme.Loader.load("nme_bitmap_data_set_bytes",4);
   #if cpp
   static var nme_bitmap_data_set_array = nme.Loader.load("nme_bitmap_data_set_array",3);
   #end
   static var nme_bitmap_data_generate_filter_rect = nme.Loader.load("nme_bitmap_data_generate_filter_rect",3);
   static var nme_render_surface_to_surface = nme.Loader.load("nme_render_surface_to_surface",-1);
   static var nme_bitmap_data_height = nme.Loader.load("nme_bitmap_data_height",1);
   static var nme_bitmap_data_width = nme.Loader.load("nme_bitmap_data_width",1);
   static var nme_bitmap_data_get_transparent = nme.Loader.load("nme_bitmap_data_get_transparent",1);
   static var nme_bitmap_data_set_flags = nme.Loader.load("nme_bitmap_data_set_flags",1);
   static var nme_bitmap_data_encode = nme.Loader.load("nme_bitmap_data_encode",3);

}
#end