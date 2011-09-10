#if flash


package nme.display;

class Tilesheet
{
	
   public var nmeBitmap:BitmapData;

   public function new(inImage:BitmapData)
   {
		nmeBitmap = inImage;
		
   }
   public function addTileRect(inRect:nme.geom.Rectangle)
   {
     
   }

}


#else


package nme.display;

class Tilesheet
{
   public var nmeHandle:Dynamic;
   public var nmeBitmap:BitmapData;

   public function new(inImage:BitmapData)
   {
		nmeBitmap = inImage;
      nmeHandle = nme_tilesheet_create(inImage.nmeHandle);
   }
   public function addTileRect(inRect:nme.geom.Rectangle)
   {
     nme_tilesheet_add_rect(nmeHandle,inRect);
   }

   static var nme_tilesheet_create = nme.Loader.load("nme_tilesheet_create",1);
   static var nme_tilesheet_add_rect = nme.Loader.load("nme_tilesheet_add_rect",2);
}


#end