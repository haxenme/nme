package nme.display;
import nme.utils.ByteArray;
import nme.geom.Rectangle;
import nme.geom.Point;
import nme.geom.Matrix;
import nme.geom.ColorTransform;
import nme.display.IBitmapDrawable;


class BitmapData
{
   private var mTextureBuffer:Dynamic;
   public var width(getWidth,null):Int;
   public var height(getHeight,null):Int;
   public var graphics(getGraphics,null):Graphics;
   public var rect(GetRect,null) : nme.geom.Rectangle;

   public static var TRANSPARENT = 0x0001;
   public static var HARDWARE    = 0x0002;


   // Have to break with flash api because we do not have real int32s ...
   public function new(inWidth:Int, inHeight:Int,
                       ?inTransparent:Bool,
                       ?inFillColour:Int,
                       ?inAlpha:Int)
   {
      if (inWidth<1 || inHeight<1)
         mTextureBuffer = null;
      else
      {
         var flags = HARDWARE;
         if (inTransparent==null || inTransparent)
            flags |= TRANSPARENT;

         var alpha:Int = inAlpha==null ? 255 : inAlpha;
         var colour:Int = inFillColour==null ? 0 : inFillColour;
         // special code to show alpha = 0 - if only neko had the 32nd bit
         if (inAlpha==null && (inFillColour==0x010101) )
            alpha = 0;


         mTextureBuffer =
            nme_create_texture_buffer(inWidth,inHeight,flags,colour,alpha);
      }
   }


   public function getGraphics() : Graphics
   {
      if (graphics==null)
         graphics = new Graphics(mTextureBuffer);
      return graphics;
   }
   public function flushGraphics()
   {
      if (graphics!=null)
         graphics.flush();
   }

   public function handle() { return mTextureBuffer; }

   public function getWidth() : Int { return nme_texture_width(mTextureBuffer); }
   public function getHeight()  : Int { return nme_texture_height(mTextureBuffer); }

   public function scroll(inDX:Int, inDY:Int)
   {
      nme_scroll_texture(handle(),inDX,inDY);
   }

   public function dispose()
   {
      mTextureBuffer = null;
   }

   public function LoadFromFile(inFilename:String)
   {
   #if neko
       mTextureBuffer = nme_load_texture(untyped inFilename.__s);
   #else
       mTextureBuffer = nme_load_texture(inFilename);
   #end
   }

   // Type = "JPG", "BMP" etc.
   public function LoadFromByteArray(inBytes:String,inType:String,
                        ?inAlpha:String )
   {
       var a:String = inAlpha==null ? "" : inAlpha;
       #if neko
       mTextureBuffer = nme_load_texture_from_bytes(untyped inBytes.__s,
                        inBytes.length,
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


   static public function CreateFromHandle(inHandle:Dynamic) : BitmapData
   {
      var result = new BitmapData(0,0);
      result.mTextureBuffer = inHandle;
      return result;
   }

   static public function Load(inFilename:String) : BitmapData
   {
      var result = new BitmapData(0,0);
      result.LoadFromFile(inFilename);
      return result;
   }

   public function GetRect() : Rectangle { return new Rectangle(0,0,width,height); }


   public function getPixels(rect:Rectangle):ByteArray
   {
      return new ByteArray(nme_texture_get_bytes(mTextureBuffer,rect));
   }

   public function setPixels(rect:Rectangle,pixels:ByteArray) : Void
   {
      nme_texture_set_bytes(mTextureBuffer,rect,pixels.get_handle());
   }

   public function setPixel(inX:Int, inY:Int,inColour:Int) : Void
   {
      nme_set_pixel(mTextureBuffer,inX,inY,inColour);
   }

   // No 32bit ints for neko...
   #if neko
   public function setPixel32(inX:Int, inY:Int,inAlpha:Int,inColour:Int) : Void
   {
      nme_set_pixel32(mTextureBuffer,inX,inY,inAlpha,inColour);
   }
   #else
   public function setPixel32(inX:Int, inY:Int,inColour:Int) : Void
   {
      nme_set_pixel32(mTextureBuffer,inX,inY,inColour);
   }
   #end


   public function clear( color : Int ) : Void
   {
       nme_surface_clear( mTextureBuffer, color );
   }
   public function fillRect( rect : nme.geom.Rectangle, inColour : Int, inAlpha:Int = 255 ) : Void
   {
      nme_tex_fill_rect(handle(),rect,inColour,inAlpha);
   }

   public function copyPixels(sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point,
      ?alphaBitmapData:BitmapData, ?alphaPoint:Point, mergeAlpha:Bool = false):Void
   {
      nme_copy_pixels(sourceBitmapData.handle(),
         sourceRect.x, sourceRect.y, sourceRect.width, sourceRect.height,
         handle(), destPoint.x, destPoint.y);
   }

   public function draw(source:IBitmapDrawable,
                 matrix:Matrix = null,
                 colorTransform:ColorTransform = null,
                 blendMode:String = null,
                 clipRect:Rectangle = null,
                 smoothing:Bool= false):Void
   {
      var gfx = source.GetBitmapDrawable();
      if (gfx!=null)
         gfx.render(matrix,mTextureBuffer);
   }

   // This is handled internally...
   public function unlock(?changeRect:nme.geom.Rectangle) { }
   public function lock() { }



   static var nme_create_texture_buffer =
                 nme.Loader.load("nme_create_texture_buffer",5);
   static var nme_load_texture = nme.Loader.load("nme_load_texture",1);
   static var nme_load_texture_from_bytes = nme.Loader.load("nme_load_texture_from_bytes",5);
   static var nme_set_pixel_data = nme.Loader.load("nme_set_pixel_data",5);
   static var nme_set_pixel = nme.Loader.load("nme_set_pixel",4);
   #if neko
   static var nme_set_pixel32 = nme.Loader.load("nme_set_pixel32",5);
   #else
   static var nme_set_pixel32 = nme.Loader.load("nme_set_pixel32",4);
   #end
   static var nme_texture_width = nme.Loader.load("nme_texture_width",1);
   static var nme_texture_height = nme.Loader.load("nme_texture_height",1);
   static var nme_texture_get_bytes = nme.Loader.load("nme_texture_get_bytes",2);
   static var nme_surface_clear = nme.Loader.load("nme_surface_clear",2);

   static var nme_texture_set_bytes = nme.Loader.load("nme_texture_set_bytes",3);
   static var nme_copy_pixels = nme.Loader.load("nme_copy_pixels",-1);
   static var nme_tex_fill_rect = nme.Loader.load("nme_tex_fill_rect",4);
   static var nme_scroll_texture = nme.Loader.load("nme_scroll_texture",3);

   static var nme_draw_object_to= nme.Loader.load("nme_draw_object_to",5);
}

