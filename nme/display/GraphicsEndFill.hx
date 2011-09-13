package nme.display;
#if cpp || neko


class GraphicsEndFill extends IGraphicsData
{

   public function new()
	{
	   super( nme_graphics_end_fill_create() );
	}

   static var nme_graphics_end_fill_create = nme.Loader.load("nme_graphics_end_fill_create",0);
}


#else
//typedef GraphicsEndFill = flash.display.GraphicsEndFill;
#end