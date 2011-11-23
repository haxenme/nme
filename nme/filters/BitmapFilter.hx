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


#else
typedef BitmapFilter = flash.filters.BitmapFilter;
#end