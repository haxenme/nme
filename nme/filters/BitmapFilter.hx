#if flash


package nme.filters;


@:native ("flash.filters.BitmapFilter")
extern class BitmapFilter {
	function new() : Void;
	function clone() : BitmapFilter;
}



#else


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


#end