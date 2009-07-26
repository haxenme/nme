package nme.display;

import nme.utils.ByteArray;
import nme.geom.Rectangle;
import nme.geom.Point;
import nme.geom.Matrix;
import nme.geom.ColorTransform;

#if neko
typedef BitmapInt32 = haxe.Int32;
#else
typedef BitmapInt32 = Int;
#end

/**
* @author	Hugh Sanderson
* @author	Russell Weir
* @todo getPixel, getPixel32 should be optimized to use library methods
*/
class BitmapData implements IBitmapDrawable
{
#if neko
   public static var CLEAR =  haxe.Int32.make(0x0000,0x0000);
   public static var BLACK =  haxe.Int32.make(0xff00,0x0000);
   public static var WHITE =  haxe.Int32.make(0xffff,0xffff);
   public static var RED =  haxe.Int32.make(0xffff,0x0000);
   public static var GREEN =  haxe.Int32.make(0xff00,0xff00);
   public static var BLUE = haxe.Int32.make(0xff00,0x00ff);

   public static var COL_MASK = haxe.Int32.make(0xff,0xffff);
#else
   public static var CLEAR = 0x00000000;
   public static var BLACK = 0xff000000;
   public static var WHITE = 0xffffffff;
   public static var RED = 0xffff0000;
   public static var GREEN = 0xff00ff00;
   public static var BLUE = 0xff0000ff;
#end

	private var mTextureBuffer:Dynamic;
	public var width(getWidth,null):Int;
	public var height(getHeight,null):Int;
	public var graphics(getGraphics,null):Graphics;
	public var rect(GetRect,null) : nme.geom.Rectangle;
	public var transparent(__getTransparent,null) : Bool;

	public static var TRANSPARENT = 0x0001;
	public static var HARDWARE    = 0x0002;


	public function new(inWidth:Int, inHeight:Int,
						inTransparent:Bool=true,
						?inFillRGBA:BitmapInt32 )
	{
		var fill_col:Int=0xffffff;
		var fill_alpha:Int=0xff;
		if (inFillRGBA!=null)
		{
			fill_col = BitmapData.extractColor(inFillRGBA);
			fill_alpha = BitmapData.extractAlpha(inFillRGBA);
		}
		if (inWidth<1 || inHeight<1) {
			mTextureBuffer = null;
		}
		else
		{
			var flags = HARDWARE;
			if (inTransparent)
				flags |= TRANSPARENT;
			mTextureBuffer =
				nme_create_texture_buffer(inWidth,inHeight,flags,fill_col,fill_alpha);
		}
	}

 	public function GetBitmapDrawable() : nme.display.Graphics {
		return new Graphics(mTextureBuffer);
	}

	/**
	* Return a Rectangle the size of the BitmapData
	*/
	public function GetRect() : Rectangle {
		return new Rectangle(0,0,width,height);
	}

	/**
	* Initialize from a file.
	*
	* @param inFilename Full or relative path to image file
	**/
	public function LoadFromFile(inFilename:String) : Void
	{
	#if neko
		mTextureBuffer = nme_load_texture(untyped inFilename.__s);
	#else
		mTextureBuffer = nme_load_texture(inFilename);
	#end
	}

	/**
	* Load texture data from RGB inBytes.
	*
	* @param inBytes
	* @param inType "JPG", "BMP" etc. (??)
	* @param inAlpha
	* @todo Document!
	**/
	public function LoadFromBytes(inBytes:haxe.io.BytesData, inType:String, ?inAlpha:String )
	{
		var a:String = inAlpha==null ? "" : inAlpha;
		#if neko
		mTextureBuffer = nme_load_texture_from_bytes(inBytes,
							neko.NativeString.length(inBytes),
							untyped inType.__s,
							untyped a.__s,
							a.length);
		#else
		mTextureBuffer = nme_load_texture_from_bytes(inBytes,
							inBytes.length,
							inType,
							a,
							a.length);
		#end
	}

	public function SetPixelData(inBuffer:String, inFormat:Int, inTableSize:Int)
	{
	#if neko
		nme_set_pixel_data(mTextureBuffer,untyped inBuffer.__s,inBuffer.length,
							inFormat, inTableSize);
	#else
		nme_set_pixel_data(mTextureBuffer,inBuffer,inBuffer.length, inFormat, inTableSize);
	#end
	}


	/////////////////// Statics ////////////////////////////
	/**
	* Create a new BitmapData instance from an existing Texture handle.
	*
	* SDL surface reference counting is handled simply - the entire "haxe" code,
	*  via grabage collection, holds exactly 1 reference the the surface.
	*  Other references may or may not be handled within the nme code.
	*/
	static public function CreateFromHandle(inHandle:Dynamic) : BitmapData
	{
		var result = new BitmapData(0,0);
		result.mTextureBuffer = inHandle;
		return result;
	}

	/**
	* Load from a file path
	*
	* @param inFilename Full or relative path to image file
	* @return New BitmapData instance representing file
	**/
	static public function Load(inFilename:String) : BitmapData
	{
		var result = new BitmapData(0,0);
		result.LoadFromFile(inFilename);
		return result;
	}



	/////////////////// Flash like API ///////////////////////

	public function clear( color : Int ) : Void
	{
		nme_surface_clear( mTextureBuffer, color );
	}

	public function clone() : BitmapData {
		/**
		var w = width;
		var h = height;
		var bm = new BitmapData(w, h, transparent);
		var rect = new Rectangle(w, h);
		bm.copyPixels(this, rect, new Point(0,0));
		**/
		var bm = new BitmapData(0, 0);
		bm.mTextureBuffer = nme_clone_texture_buffer(mTextureBuffer);
		return bm;
	}

	public function copyPixels(sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point,
		?alphaBitmapData:BitmapData, ?alphaPoint:Point, mergeAlpha:Bool = false):Void
	{
		nme_copy_pixels(sourceBitmapData.handle(),
			sourceRect.x, sourceRect.y, sourceRect.width, sourceRect.height,
			handle(), destPoint.x, destPoint.y);
	}

	public function dispose()
	{
		mTextureBuffer = null;
	}

	public function draw(source:IBitmapDrawable,
					matrix:Matrix = null,
					colorTransform:ColorTransform = null,
					blendMode:String = null,
					clipRect:Rectangle = null,
					smoothing:Bool= false):Void
	{
		source.drawToSurface(mTextureBuffer,matrix,colorTransform,blendMode,clipRect,smoothing);
	}

   // IBitmapDrawable interface...
   public function drawToSurface(inSurface : Dynamic,
               matrix:nme.geom.Matrix,
               colorTransform:nme.geom.ColorTransform,
               blendMode:String,
               clipRect:nme.geom.Rectangle,
               smoothing:Bool):Void
	{
	   // TODO: This is a bit of a placeholder for now.
	   if (matrix==null) matrix = new Matrix();
		nme_copy_pixels(handle(),
			0.0,0.0,width+0.0,height+0.0,
			inSurface(), matrix.tx, matrix.ty);
	}



	public function fillRect( rect : nme.geom.Rectangle, inColour : BitmapInt32 ) : Void
	{
		var a = extractAlpha(inColour);
		var c = extractColor(inColour);
		nme_tex_fill_rect(handle(), rect, c, a);
	}

	public function fillRectEx( rect : nme.geom.Rectangle, inColour : Int, inAlpha:Int = 255 ) : Void
	{
		nme_tex_fill_rect(handle(),rect,inColour,inAlpha);
	}

	public function flushGraphics()
	{
		if (graphics!=null)
			graphics.flush();
	}

	/**
	* @todo Implement
	*/
	public function getColorBoundsRect(mask:BitmapInt32, color: BitmapInt32, findColor:Bool = true):Rectangle
	{
		return new Rectangle(width, height);
	}

	public function getGraphics() : Graphics
	{
		if (graphics==null)
			graphics = new Graphics(mTextureBuffer);
		return graphics;
	}

	public function getHeight()  : Int { return nme_texture_height(mTextureBuffer); }

	public function getWidth() : Int { return nme_texture_width(mTextureBuffer); }


	/**
	* @todo move to property
	*/
	public function handle() : Dynamic
        {
           return mTextureBuffer;
        }



	public function getPixels(rect:Rectangle):ByteArray
	{
		return new ByteArray(nme_texture_get_bytes(mTextureBuffer,rect));
	}

	public function getPixel(x:Int, y:Int) : Int
	{
		return untyped nme_get_pixel(mTextureBuffer, x, y);
	}

	public function getPixel32(x:Int, y:Int) : BitmapInt32
	{
		return untyped nme_get_pixel32(mTextureBuffer, x, y);
	}

	// Handled internally...
	public function lock() { }

	public function scroll(inDX:Int, inDY:Int)
	{
		nme_scroll_texture(handle(),inDX,inDY);
	}

	public function setPixel(inX:Int, inY:Int,inColour:Int) : Void
	{
		nme_set_pixel(mTextureBuffer,inX,inY,inColour);
	}

	public function setPixel32(inX:Int, inY:Int, inColour: BitmapInt32) : Void
	{
		nme_set_pixel32(mTextureBuffer, inX, inY, inColour);
	}

	/**
	* Sets colour with an alpha and RGB value
	*/
	public function setPixel32Ex(inX:Int, inY:Int, inAlpha:Int, inColour:Int) : Void
	{
		nme_set_pixel32_ex(mTextureBuffer, inX, inY, inAlpha, inColour);
	}

	public function setPixels(rect:Rectangle,pixels:ByteArray) : Void
	{
		nme_texture_set_bytes(mTextureBuffer,rect,pixels.get_handle());
	}

	// Handled internally...
	public function unlock(?changeRect:nme.geom.Rectangle) { }

	///////////// statics ///////////////////////////

	public static inline function extractAlpha(v : BitmapInt32) : Int {
		return
			#if neko
				haxe.Int32.toInt(haxe.Int32.ushr(v, 24));
			#else
				v >>> 24;
			#end
	}

	public static inline function extractColor(v : BitmapInt32) : Int {
		return
			#if neko
				haxe.Int32.toInt(haxe.Int32.and(v,COL_MASK));
			#else
				v & 0xFFFFFF;
			#end
	}

	private function __getTransparent() : Bool {
		return untyped nme_get_transparent(mTextureBuffer);
	}

	static var nme_clone_texture_buffer = nme.Loader.load("nme_clone_texture_buffer", 1);
	static var nme_copy_pixels = nme.Loader.load("nme_copy_pixels",-1);
	static var nme_create_texture_buffer = nme.Loader.load("nme_create_texture_buffer",5);
	static var nme_draw_object_to= nme.Loader.load("nme_draw_object_to",5);
	static var nme_get_pixel = nme.Loader.load("nme_get_pixel", 3);
	static var nme_get_pixel32 =  nme.Loader.load("nme_get_pixel32", 3);
	static var nme_get_transparent = nme.Loader.load("nme_get_transparent", 1);
	static var nme_load_texture = nme.Loader.load("nme_load_texture",1);
	static var nme_load_texture_from_bytes = nme.Loader.load("nme_load_texture_from_bytes",5);
	static var nme_scroll_texture = nme.Loader.load("nme_scroll_texture",3);
	static var nme_set_pixel = nme.Loader.load("nme_set_pixel",4);
	static var nme_set_pixel32 = nme.Loader.load("nme_set_pixel32",4);
	static var nme_set_pixel32_ex = nme.Loader.load("nme_set_pixel32_ex",5);
	static var nme_set_pixel_data = nme.Loader.load("nme_set_pixel_data",5);
	static var nme_surface_clear = nme.Loader.load("nme_surface_clear",2);
	static var nme_tex_fill_rect = nme.Loader.load("nme_tex_fill_rect",4);
	static var nme_texture_get_bytes = nme.Loader.load("nme_texture_get_bytes",2);
	static var nme_texture_height = nme.Loader.load("nme_texture_height",1);
	static var nme_texture_set_bytes = nme.Loader.load("nme_texture_set_bytes",3);
	static var nme_texture_width = nme.Loader.load("nme_texture_width",1);

}

