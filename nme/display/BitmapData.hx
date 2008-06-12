package nme.display;
import nme.utils.ByteArray;
import nme.geom.Rectangle;


class BitmapData
{
   private var mTextureBuffer:Void;
   public var width(getWidth,null):Int;
   public var height(getHeight,null):Int;
   public var graphics(getGraphics,null):Graphics;

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


   public function destroy()
   {
      mTextureBuffer = null;
   }

   public function LoadFromFile(inFilename:String)
   {
       mTextureBuffer = nme_load_texture(untyped inFilename.__s);
   }

   // Type = "JPG", "BMP" etc.
   public function LoadFromByteArray(inBytes:String,inType:String,
                        ?inAlpha:String )
   {
       var a:String = inAlpha==null ? "" : inAlpha;
       mTextureBuffer = nme_load_texture_from_bytes(untyped inBytes.__s,
                        inBytes.length,
                        untyped inType.__s,
                        untyped a.__s,
                        a.length);
   }

   public function SetPixelData(inBuffer:String, inFormat:Int, inTableSize:Int)
   {
      nme_set_pixel_data(mTextureBuffer,untyped inBuffer.__s,inBuffer.length,
                          inFormat, inTableSize);
   }



   static public function Load(inFilename:String) : BitmapData
   {
      var result = new BitmapData(0,0);
      result.LoadFromFile(inFilename);
      return result;
   }

   public function getPixels(rect:Rectangle):ByteArray
   {
      return new ByteArray(nme_texture_get_bytes(mTextureBuffer,rect));
   }

   public function setPixels(rect:Rectangle,pixels:ByteArray) : Void
   {
      nme_texture_set_bytes(mTextureBuffer,rect,pixels.get_handle());
   }

   public function clear( color : Int )
   {
       nme_surface_clear( mTextureBuffer, color );
   }




   static var nme_create_texture_buffer =
                 neko.Lib.load("nme","nme_create_texture_buffer",5);
   static var nme_load_texture = neko.Lib.load("nme","nme_load_texture",1);
   static var nme_load_texture_from_bytes = neko.Lib.load("nme","nme_load_texture_from_bytes",5);
   static var nme_set_pixel_data = neko.Lib.load("nme","nme_set_pixel_data",5);
   static var nme_texture_width = neko.Lib.load("nme","nme_texture_width",1);
   static var nme_texture_height = neko.Lib.load("nme","nme_texture_height",1);
   static var nme_texture_get_bytes = neko.Lib.load("nme","nme_texture_get_bytes",2);
   static var nme_surface_clear = neko.Lib.load("nme","nme_surface_clear",2);

   static var nme_texture_set_bytes = neko.Lib.load("nme","nme_texture_set_bytes",3);
}

