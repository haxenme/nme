#if flash


package nme.display;

@:native ("flash.display.GraphicsEndFill")
extern class GraphicsEndFill implements IGraphicsData {
	function new() : Void;
}


#else


package nme.display;

class GraphicsEndFill extends IGraphicsData
{

   public function new()
	{
	   super( nme_graphics_end_fill_create() );
	}

   static var nme_graphics_end_fill_create = nme.Loader.load("nme_graphics_end_fill_create",0);
}


#end