package nme.filters;


#if flash
@:native ("flash.filters.BitmapFilter")
extern class BitmapFilter {
	function new() : Void;
	function clone() : BitmapFilter;
}
#else



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
#end