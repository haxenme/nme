package nme.display;

class Tilesheet
{
   public var nmeHandle:Dynamic;
   var mData:BitmapData;

   public function new(inImage:BitmapData)
   {
      nmeHandle = nme_tilesheet_create(inImage.nmeHandle);
   }
   public function addTileRect(inRect:nme.geom.Rectangle)
   {
     nme_tilesheet_add_rect(nmeHandle,inRect);
   }

   static var nme_tilesheet_create = nme.Loader.load("nme_tilesheet_create",1);
   static var nme_tilesheet_add_rect = nme.Loader.load("nme_tilesheet_add_rect",2);
}
