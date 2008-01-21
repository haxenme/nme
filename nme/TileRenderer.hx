package nme;

class TileRenderer
{
   var mRenderer : Void;
   public var width(getWidth,null):Int;
   public var height(getHeight,null):Int;


   public function new(inTexture:nme.BitmapData,
                       inX0:Int,
                       inY0:Int,
                       inWidth:Int,
                       inHeight:Int,
                       ?inSurface:Void)
   {
      var surface = inSurface==null ?  Manager.getScreen() : inSurface;

      mRenderer = nme_create_tile_renderer(inTexture.handle(), surface,
                      inX0,inY0,inWidth,inHeight);
   }
   public function Blit(inX0:Int,inY0:Int)
   {
       nme_blit_tile(mRenderer,inX0,inY0);
   }

   public function getWidth() : Int { return nme_tile_renderer_width(mRenderer); }
   public function getHeight()  : Int { return nme_tile_renderer_height(mRenderer); }



   static var nme_create_tile_renderer = neko.Lib.load("nme",
                    "nme_create_tile_renderer", -1 );
   static var nme_blit_tile = neko.Lib.load("nme", "nme_blit_tile", 3 );
   static var nme_tile_renderer_width = neko.Lib.load("nme", "nme_tile_renderer_width", 1 );
   static var nme_tile_renderer_height = neko.Lib.load("nme", "nme_tile_renderer_height", 1 );
}
