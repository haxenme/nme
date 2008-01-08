package nme;

class TileRenderer
{
   var mRenderer : Void;

   public function new(inTexture:nme.BitmapData,
                       inSurface:Void,
                       inX0:Int,
                       inY0:Int,
                       inWidth:Int,
                       inHeight:Int )
   {
      mRenderer = nme_create_tile_renderer(inTexture.handle(), inSurface,
                      inX0,inY0,inWidth,inHeight);
   }
   public function Blit(inX0:Int,inY0:Int)
   {
       nme_blit_tile(mRenderer,inX0,inY0);
   }

   static var nme_create_tile_renderer = neko.Lib.load("nme",
                    "nme_create_tile_renderer", -1 );
   static var nme_blit_tile = neko.Lib.load("nme", "nme_blit_tile", 3 );
}
