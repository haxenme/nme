package nme.filters;
#if (cpp || neko)


class BitmapFilter
{
	
	private var type:String;
	
	
	public function new (inType)
	{
		type = inType;
	}
	
	
	public function clone():BitmapFilter
	{
		throw("clone not implemented");
		return null;
	}
	
}


#elseif js


import Html5Dom;

class BitmapFilter
{
   var mType:String;

   public function new(inType) { mType = inType; }
   public function clone() : flash.filters.BitmapFilter
   {
      throw "Implement in subclass. BitmapFilter::clone";
      return null;
   }

   public function jeashPreFilter(surface:HTMLCanvasElement) {}

   public function jeashApplyFilter(surface:HTMLCanvasElement) {}
}


#else
typedef BitmapFilter = flash.filters.BitmapFilter;
#end