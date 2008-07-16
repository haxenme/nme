package nme.filters;

class BitmapFilter
{
   var mType:String;

   public function new(inType) { mType = inType; }
   public function clone() : nme.filters.BitmapFilter
   {
      throw("clone not implemented");
      return null;
   }
}
