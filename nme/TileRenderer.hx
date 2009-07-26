package nme;

class TileRenderer
{
   var mRenderer : Dynamic;
   public var width(getWidth,null):Int;
   public var height(getHeight,null):Int;


   public function new(inTexture:nme.display.BitmapData,
                       inX0:Int,
                       inY0:Int,
                       inWidth:Int,
                       inHeight:Int,
                       inHotX:Float,
                       inHotY:Float,
                       ?inSurface:Dynamic)
   {
      var surface = inSurface==null ?  Manager.getScreen() : inSurface;

      mRenderer = nme_create_blitter(inTexture.handle(), surface,
                      inX0,inY0,inWidth,inHeight,inHotX,inHotY);
   }
   public function Blit(inX0:Float,inY0:Float,inTheta:Float,inScale:Float)
   {
       nme_blit_tile(mRenderer,inX0,inY0,inTheta,inScale);
   }

   public function getWidth() : Int { return nme_tile_renderer_width(mRenderer); }
   public function getHeight()  : Int { return nme_tile_renderer_height(mRenderer); }



   static var nme_create_blitter = nme.Loader.load("nme_create_blitter", -1 );
   static var nme_blit_tile = nme.Loader.load("nme_blit_tile", 5 );
   static var nme_tile_renderer_width = nme.Loader.load("nme_tile_renderer_width", 1 );
   static var nme_tile_renderer_height = nme.Loader.load("nme_tile_renderer_height", 1 );
}
