package nme;

class BitmapData
{
   private var mTextureBuffer:Void;
   public var width(getWidth,null):Int;
   public var height(getHeight,null):Int;

   public static var TRANSPARENT = 0x0001;
   public static var HARDWARE    = 0x0002;


   public function new(inWidth:Int, inHeight:Int,
                       ?inTransparent:Bool, ?inFillColour:neko.Int32)
   {
      if (inWidth<1 || inHeight<1)
         mTextureBuffer = null;
      else
      {
         var flags = 0;
         if (inTransparent==null || inTransparent)
            flags |= TRANSPARENT;

         var alpha:Int;
         var colour:Int;

         if (inFillColour==null)
         {
            alpha = 255;
            colour = 0xffffff;
         }
         else
         {
            colour = neko.Int32.toInt(inFillColour) & 0xffffff;
            alpha =  neko.Int32.toInt( neko.Int32.ushr(inFillColour,24) ) &0xff;
         }


         mTextureBuffer =
            nme_create_texture_buffer(inWidth,inHeight,flags,colour,alpha);
      }
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

