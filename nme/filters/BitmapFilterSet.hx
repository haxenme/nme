package nme.filters;

import nme.geom.Point;
import nme.display.BitmapData;

class BitmapFilterSet
{
   var mHandle:Dynamic;
   var mOffset:Point;

   public function new(inFilters:Array<Dynamic>)
   {
      mOffset = new Point();
      #if neko
      mHandle = nme_create_filter_set(untyped inFilters.__neko(),mOffset);
      #else
      mHandle = nme_create_filter_set(inFilters,mOffset);
      #end 
   }

   public function FilterImage(inImage:BitmapData) : BitmapData
   {
      var texture_handle = nme_filter_image(mHandle,inImage.handle());
      return BitmapData.CreateFromHandle(texture_handle);
   }

   public function GetOffsetX() : Int { return Std.int(mOffset.x); }
   public function GetOffsetY() : Int { return Std.int(mOffset.y); }



   static var nme_filter_image = nme.Loader.load("nme_filter_image",2);
   static var nme_create_filter_set = nme.Loader.load("nme_create_filter_set",2);
}


