package nme.filters;

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
