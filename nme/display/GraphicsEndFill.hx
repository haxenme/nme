package nme.display;
#if (cpp || neko)


import nme.Loader;


class GraphicsEndFill extends IGraphicsData
{	
	
	public function new()
	{
		
		super(nme_graphics_end_fill_create());
		
	}
	
	
	private static var nme_graphics_end_fill_create = Loader.load("nme_graphics_end_fill_create", 0);
	
}


#else
//typedef GraphicsEndFill = flash.display.GraphicsEndFill;
#end