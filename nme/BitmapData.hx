package nme;

class BitmapData
{
   private var mTextureBuffer:Void;
   public var width(getWidth,null):Int;
   public var height(getHeight,null):Int;
   public var graphics(getGraphics,null):nme.Graphics;

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
         var colour:Int = inFillColour==null ? 255 : inFillColour;

         mTextureBuffer =
            nme_create_texture_buffer(inWidth,inHeight,flags,colour,alpha);
      }
   }

   public function getGraphics() : nme.Graphics
   {
      if (graphics==null)
         graphics = new nme.Graphics(mTextureBuffer);
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

   static public function Load(inFilename:String) : BitmapData
   {
      var result = new BitmapData(0,0);
      result.LoadFromFile(inFilename);
      return result;
   }


   static var nme_create_texture_buffer =
                 neko.Lib.load("nme","nme_create_texture_buffer",5);
   static var nme_load_texture = neko.Lib.load("nme","nme_load_texture",1);
   static var nme_texture_width = neko.Lib.load("nme","nme_texture_width",1);
   static var nme_texture_height = neko.Lib.load("nme","nme_texture_height",1);
}

