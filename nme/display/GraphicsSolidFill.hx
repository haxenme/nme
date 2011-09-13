package nme.display;
#if (cpp || neko)


class GraphicsSolidFill extends IGraphicsData
{

   public function new(color:Int = 0, alpha:Float = 1.0)
	{
	   super( nme_graphics_solid_fill_create(color,alpha) );
	}

   static var nme_graphics_solid_fill_create = nme.Loader.load("nme_graphics_solid_fill_create",2);
}


#else
//typedef GraphicsSolidFill = flash.display.GraphicsSolidFill;
#end