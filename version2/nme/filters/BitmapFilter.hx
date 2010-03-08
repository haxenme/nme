package nme.filters;

class BitmapFilter
{
   var nmeType:String;

   function new(inType) { nmeType = inType; }

   public function clone() : nme.filters.BitmapFilter
   {
      throw("clone not implemented");
      return null;
   }
}
