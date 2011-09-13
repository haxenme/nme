package nme.filters;
#if (cpp || neko)


class BitmapFilter
{
   var type:String;

   function new(inType) { type = inType; }

   public function clone() : nme.filters.BitmapFilter
   {
      throw("clone not implemented");
      return null;
   }
}


#else
typedef BitmapFilter = flash.filters.BitmapFilter;
#end